#include <cstdio>
#include <iostream>
#include <cstdlib>
#include <climits>
#include <cstring>
#include <vector>
#include <cctype>
#include <SDL.h>

#include "Vsmstang_top.h"
#include "Vsmstang_top_smstang_top.h"

#include "verilated.h"
#include <verilated_fst_c.h>

#define TRACE_ON

using namespace std;

// See: https://projectf.io/posts/verilog-sim-verilator-sdl/
const int H_RES = 256;
const int V_RES = 192;
int resolution_x = H_RES;
int resolution_y = V_RES;

typedef struct Pixel
{			   // for SDL texture
	uint8_t a; // transparency
	uint8_t b; // blue
	uint8_t g; // green
	uint8_t r; // red
} Pixel;

Pixel screenbuffer[H_RES * V_RES];

long long max_sim_time = 0LL;

bool trace_toggle;				// -t or "t" key
bool trace_loading;				// -tl option
long long start_trace_time;		// -tt option
int start_trace_frame;			// -tf option
bool showFrameCount = true;

void usage()
{
	printf("Usage: sim [options] <rom_file>\n");
	printf("  -t     start tracing once sms is on (to waveform.fst)\n");
	printf("  -tt T  start tracing from time T\n");
	printf("  -tf F  start tracing from frame F\n");
	printf("  -tl    start tracing from game loading (i.e. before md is turned on)\n");
	printf("  -s T   stop simulation at time T\n");
	printf("  -f     print flash related memory accesses\n");
}

void help() {
	printf("ROM loaded. Use these keys in the simulation window for controls:\n");
	printf("SPC: Start/stop simulation.      ESC: Quit.     T: toggle tracing on/off\n");
	printf("Arrow keys: D-pad, A: A button, S: B button, D: C button, Q: X button, W: Y button, E: Z Select, Z: Start, X: Mode\n");
	// printf("V: dump VRAM.\n");
	// printf("I: show additional info like frame count.\n");
}

VerilatedFstC *m_trace;
Vsmstang_top *top = new Vsmstang_top;
Vsmstang_top_smstang_top *sms = top->smstang_top;
uint64_t sim_time;
uint8_t clkcnt;
int hblank_r, ce_pix_r;

// split by spaces
vector<string> tokenize(string s);
long long parse_num(string s);
void trace_on();
void trace_off();

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vsmstang_top_smstang_top *sms = top->smstang_top;
	bool frame_updated = false;
	uint64_t start_ticks = SDL_GetPerformanceCounter();
	int frame_count = 0;

	// if (argc == 1)
	// {
	// 	usage();
	// 	exit(1);
	// }

	// parse options
	bool loaded = false;
	for (int i = 1; i < argc; i++)
	{
		char *eptr;
		if (strcmp(argv[i], "-t") == 0)
		{
			trace_toggle = true;
			printf("Tracing ON\n");
			trace_on();
		}
		else if (strcmp(argv[i], "-s") == 0 && i + 1 < argc)
		{
			max_sim_time = strtoll(argv[++i], &eptr, 10);
			if (max_sim_time == 0)
				printf("Simulating forever.\n");
			else
				printf("Simulating %lld steps\n", max_sim_time);
		}
		else if (strcmp(argv[i], "-tt") == 0 && i + 1 < argc) {
			start_trace_time = strtoll(argv[++i], &eptr, 10);
			printf("Start tracing from %lld\n", start_trace_time);
		}
		else if (strcmp(argv[i], "-tf") == 0 && i + 1 < argc) {
			start_trace_frame = atoi(argv[++i]);
			printf("Start tracing from frame %d\n", start_trace_frame);
		}
		else if (strcmp(argv[i], "-tl") == 0) {
			trace_loading = true;
			trace_on();
			trace_toggle = true;
			printf("Include loading in tracing\n");
		}
		else if (argv[i][0] == '-') {
			printf("Unrecognized option: %s\n", argv[i]);
			usage();
			exit(1);
		}
		else
		{
			// load ROM
			// load_rom(argv[i]);
			loaded = true;

			if (!trace_loading)
				sim_time = 0;		// return sim_time to 0 when we are not tracing loading
		}
	}
	// if (!loaded)
	// {
	// 	usage();
	// 	exit(1);
	// }

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
	{
		printf("SDL init failed.\n");
		return 1;
	}

	SDL_Window *sdl_window = NULL;
	SDL_Renderer *sdl_renderer = NULL;
	SDL_Texture *sdl_texture = NULL;

	sdl_window = SDL_CreateWindow("SMSTang Sim", SDL_WINDOWPOS_CENTERED,
								  SDL_WINDOWPOS_CENTERED, H_RES * 2, V_RES * 2, SDL_WINDOW_SHOWN);
	if (!sdl_window)
	{
		printf("Window creation failed: %s\n", SDL_GetError());
		return 1;
	}
	sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
									  SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
	if (!sdl_renderer)
	{
		printf("Renderer creation failed: %s\n", SDL_GetError());
		return 1;
	}

	sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_RGBA8888,
									SDL_TEXTUREACCESS_TARGET, H_RES, V_RES);
	if (!sdl_texture)
	{
		printf("Texture creation failed: %s\n", SDL_GetError());
		return 1;
	}

	FILE *f = fopen("sms.aud", "w");
	long long samples = 0;
	bool sample_valid = false;

	bool sim_on = true; // max_sim_time > 0;
	bool done = false;
	uint64_t cnt = 0;

	SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
	SDL_RenderClear(sdl_renderer);
	SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
	SDL_RenderPresent(sdl_renderer);
	SDL_StopTextInput(); // for SDL_KEYDOWN

	help();

	uint64_t last_pixel_time = sim_time, last_frame_time = sim_time;
	while (!done)
	{
		cnt++;

		if (sim_on && max_sim_time > 0 && sim_time >= max_sim_time) {
			printf("Simulation time is up: sim_time=%" PRIu64 "\n", sim_time);
			sim_on = false;
		}

		if (sim_on) {

			sim_time++;

			top->clk_g = !top->clk_g;
			top->eval();

			if (	trace_toggle ||
					start_trace_time != 0 && sim_time == start_trace_time ||
					start_trace_frame != 0 && frame_count == start_trace_frame) 
			{
				trace_toggle = true;
				trace_on();
				m_trace->dump(sim_time);
			}

			// collect audio samples @ 48Khz
			if (sim_time % (53693175 * 2 / 48000) == 0 && !sms->reset) {
				uint16_t ar, al;
				ar = sms->audio_r;
				al = sms->audio_l;
				if (al != 0 || ar != 0)
					sample_valid = true;
				fwrite(&al, sizeof(al), 1, f);
				fwrite(&ar, sizeof(ar), 1, f);
				samples++;
				if (samples % 1000 == 0 && sample_valid)
				{
					printf("%lld sound samples\n", samples);
					sample_valid = false;
				}
			}

			if (sms->ce_pix && !ce_pix_r && sms->x < H_RES && sms->y < V_RES) {
				Pixel *p = &screenbuffer[sms->y * H_RES + sms->x];
				p->a = 0xff;
				p->r = (sms->color & 0xf) << 4;
				p->g = sms->color& 0xf0;
				p->b = (sms->color & 0xf00) >> 4;

				if (sim_time % 10000000 == 0) {
					uint64_t pix_time = sim_time - last_pixel_time;
					printf("Pixel clock: %fMhz\n", (double)(53593175 * 2) / pix_time / 1000000);
				}
				last_pixel_time = sim_time;
				// if (p->r || p->g || p->b) {
				// 	printf("Pixel: %d, %d, %d, %d, %d\n", pixel_x, pixel_y, p->r, p->g, p->b);
				// }
			}
			ce_pix_r = sms->ce_pix;

			// update texture once per frame (in blanking)
			if (sms->VS) {
				if (!frame_updated)
				{
					// check resolution
					resolution_x = 256; resolution_y = 192;

					frame_updated = true;
					SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
					SDL_RenderClear(sdl_renderer);
					const SDL_Rect srcRect = {0, 0, resolution_x, resolution_y};
					SDL_RenderCopy(sdl_renderer, sdl_texture, &srcRect, NULL);
					SDL_RenderPresent(sdl_renderer);
					frame_count++;

					if (frame_count % 5 == 0 || m_trace)
						printf("Frame #%d. Framerate %4.1f\n", frame_count, (double)53693715*2/(sim_time - last_frame_time));
					last_frame_time = sim_time;

					if (showFrameCount) {
						SDL_SetWindowTitle(sdl_window, ("SMSTang Sim - frame " + to_string(frame_count) + 
											(trace_toggle ? " tracing" : "")).c_str());
					} else {
						SDL_SetWindowTitle(sdl_window, "SMSTang Sim");
					}
				}
			}
			else
				frame_updated = false;
		}

		if (cnt % 100 == 0)
		{
			// check for SDL events
			SDL_Event e;
			if (SDL_PollEvent(&e))
			{
				// printf("Event type: %d, SDL_KEYDOWN=%d\n", e.type, SDL_KEYDOWN);
				switch (e.type) {
				
				case SDL_QUIT:
					done = true;
					break;
				case SDL_KEYDOWN:
					// printf("Key pressed: %d\n", e.key.keysym.sym);
					switch (e.key.keysym.sym) {
					case SDLK_SPACE: 
						sim_on = !sim_on;
						max_sim_time = 0;
						if (sim_on)
							printf("Simulation started\n");
						else
							printf("Simulation stopped: sim_time=%" PRIu64 "\n", sim_time);
						break;
					case SDLK_ESCAPE: 	done = true; break;
					// case SDLK_p:		showSpritesWindow(); break;
					// case SDLK_m:        showTilemapWindow(); break;
					case SDLK_t:		trace_toggle = !trace_toggle; break;
					case SDLK_v: {
						cout << "VRAM dumping not implemented yet" << endl;
						break;
					}
					case SDLK_i:	showFrameCount = !showFrameCount; break;
					}
					// FALL THROUGH				
				case SDL_KEYUP:
					// (R L X A RT LT DN UP START SELECT Y B)
					int bit;
					switch (e.key.keysym.sym) {
					case SDLK_UP:		bit = 4; break;
					case SDLK_DOWN:		bit = 5; break;
					case SDLK_LEFT:		bit = 6; break;
					case SDLK_RIGHT:	bit = 7; break;
					case SDLK_a:		bit = 1; break; // Y  (mapped to MD A)
					case SDLK_s:		bit = 0; break;	// B  (mapped to MD B)
					case SDLK_d:		bit = 8; break;	// A  (mapped to MD C)
					case SDLK_w:		bit = 3; break; // X
					case SDLK_z:		bit = 10; break; // L
					case SDLK_x:		bit = 11; break; // R
					case SDLK_RETURN:   bit = 3; break; // Start
					default: 			bit = -1; break;
					} 
					if (bit >= 0) {
						// if (e.type == SDL_KEYDOWN) 
						// 	top->joy_btns |= 1 << bit;
						// else
						// 	top->joy_btns &= ~(1 << bit);
					}

					break;
				case SDL_WINDOWEVENT:
					if (e.window.event == SDL_WINDOWEVENT_CLOSE) {
						 if (e.window.windowID == SDL_GetWindowID(sdl_window))
							done = true;
					}
					break;
				}
			}
		}
	}

	fclose(f);
	printf("Audio output to md.aud done.\n");

	if (m_trace)
		m_trace->close();
	delete top;

	// calculate frame rate
	uint64_t end_ticks = SDL_GetPerformanceCounter();
	double duration = ((double)(end_ticks - start_ticks)) / SDL_GetPerformanceFrequency();
	double fps = (double)frame_count / duration;
	printf("Frames per second: %.1f. Total frames=%d\n", fps, frame_count);

	SDL_DestroyTexture(sdl_texture);
	SDL_DestroyRenderer(sdl_renderer);
	SDL_DestroyWindow(sdl_window);
	SDL_Quit();

	return 0;
}


bool is_space(char c)
{
	return c == ' ' || c == '\t';
}

vector<string> tokenize(string s)
{
	string w;
	vector<string> r;

	for (int i = 0; i < s.size(); i++)
	{
		char c = s[i];
		if (is_space(c) && w.size() > 0)
		{
			r.push_back(w);
			w = "";
		}
		if (!is_space(c))
			w += c;
	}
	if (w.size() > 0)
		r.push_back(w);
	return r;
}

// parse something like 100m or 10k
// return -1 if there's an error
long long parse_num(string s)
{
	long long times = 1;
	if (s.size() == 0)
		return -1;
	char last = tolower(s[s.size() - 1]);
	if (last >= 'a' && last <= 'z')
	{
		s = s.substr(0, s.size() - 1);
		if (last == 'k')
			times = 1000LL;
		else if (last == 'm')
			times = 1000000LL;
		else if (last == 'g')
			times = 1000000000LL;
		else
			return -1;
	}
	return atoll(s.c_str()) * times;
}

void trace_on()
{
	if (!m_trace)
	{
		m_trace = new VerilatedFstC;
		top->trace(m_trace, 5);
		Verilated::traceEverOn(true);
		m_trace->open("waveform.fst");
	}
}

void trace_off()
{
	if (m_trace)
	{
		top->trace(m_trace, 0);
	}
}

