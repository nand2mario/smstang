
module lightgun
(
	input        CLK,
	input        RESET,

	input [24:0] MOUSE,
	input        MOUSE_XY,

	input  [7:0] JOY_X,
	input  [7:0] JOY_Y,
	input [11:0] JOY,

	input        HDE,VDE,
	input        CE_PIX,

	input        BTN_MODE,
	input  [1:0] SIZE,
	
	input  [7:0] SENSOR_DELAY,
	
	output       TARGET,
	output reg   SENSOR,
	output reg   TRIGGER
);

assign TARGET  = ~offscreen & draw;

reg  [8:0] lg_x, x;
reg  [8:0] lg_y, y;

wire [9:0] new_x = {lg_x[8],lg_x} + {{2{MOUSE[4]}},MOUSE[15:8]};
wire [9:0] new_y = {lg_y[8],lg_y} - {{2{MOUSE[5]}},MOUSE[23:16]};

wire [8:0] j_x = {~JOY_X[7], JOY_X[6:0]};
wire [8:0] j_y = {~JOY_Y[7], JOY_Y[6:0]};

reg offscreen = 0, draw = 0;
always @(posedge CLK) begin
	reg old_pix, old_hde, old_vde, old_ms;
	reg [8:0] hcnt;
	reg [8:0] vcnt;
	reg [8:0] vtotal;
	reg [15:0] hde_d;
	reg [8:0] xm,xp;
	reg [8:0] ym,yp;
	reg [8:0] cross_sz;
	reg sensor_pend;
	reg [7:0] sensor_time;
	
	TRIGGER <= BTN_MODE ? MOUSE[0] : (JOY[4]|JOY[9]);

	case(SIZE)
			0: cross_sz <= 8'd1;
			1: cross_sz <= 8'd3;
	default: cross_sz <= 8'd0;
	endcase
	
	old_ms <= MOUSE[24];
	if(MOUSE_XY) begin
		if(old_ms ^ MOUSE[24]) begin
			if(new_x[9]) lg_x <= 0;
			else if(new_x[8]) lg_x <= 255;
			else lg_x <= new_x[8:0];

			if(new_y[9]) lg_y <= 0;
			else if(new_y > vtotal) lg_y <= vtotal;
			else lg_y <= new_y[8:0];
		end
	end
	else begin
		lg_x <= j_x;

		if(j_y < 8) lg_y <= 0;
		else if((j_y - 9'd8) > vtotal) lg_y <= vtotal;
		else lg_y <= j_y - 9'd8;
	end

	if(CE_PIX) begin
		hde_d <= {hde_d[14:0],HDE};
		old_hde <= hde_d[15];
		if(~&hcnt) hcnt <= hcnt + 1'd1;
		if(~old_hde & ~HDE) hcnt <= 0;
		if(old_hde & ~hde_d[15]) begin
			if(~VDE) begin
				vcnt <= 0;
				if(vcnt) vtotal <= vcnt - 1'd1;
			end
			else if(~&vcnt) vcnt <= vcnt + 1'd1;
		end
		
		old_vde <= VDE;
		if(~old_vde & VDE) begin
			x  <= lg_x;
			y  <= lg_y;
			xm <= lg_x - cross_sz;
			xp <= lg_x + cross_sz;
			ym <= lg_y - cross_sz;
			yp <= lg_y + cross_sz;
			offscreen <= !lg_y[7:1] || lg_y >= (vtotal-1'd1);
		end
		
		if(~&sensor_time) sensor_time <= sensor_time + 1'd1;
		if(sensor_pend) begin
			if (sensor_time >= (SENSOR_DELAY)) begin
				SENSOR <= !offscreen;
				sensor_pend <= 1'b0;
				sensor_time <= 8'd0;
			end
		end
		// Keep sensor active for a bit to mimic real light gun behavior.
		else if(sensor_time > 64) SENSOR <= 1'b0;
	end

	if(HDE && VDE && (x == hcnt) && (y <= vcnt) && (y > vcnt - 8)) begin
		sensor_pend <= 1'b1;
		sensor_time <= 8'd0;
	end
	
	draw <= (((SIZE[1] || ($signed(hcnt) >= $signed(xm) && hcnt <= xp)) && y == vcnt) || 
				((SIZE[1] || ($signed(vcnt) >= $signed(ym) && vcnt <= yp)) && x == hcnt));
end

endmodule