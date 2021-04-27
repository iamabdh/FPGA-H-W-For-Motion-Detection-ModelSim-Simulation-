module pir (
    clk, 
    turn,
    stop_alarm,
    pir_sensor_1,
    pir_sensor_2,
    pir_sensor_3,
    LED,  // On: motion, Off: no motion
    buzzer, // On: motion, Off: no motion 
    display_data
);

// ----------------
// input Ports
// ----------------

input           clk;
input           turn;
input           stop_alarm;
input   [6:0]   pir_sensor_1;
input   [6:0]   pir_sensor_2;
input   [6:0]   pir_sensor_3;

// ----------------
// Output Ports
// ----------------

output reg  [2:0]  LED;  
output reg         buzzer;
output reg [30:0]  display_data;

// ----------------
// Lacal parameters 
// ----------------

localparam INIT             = 4'b0001;
localparam IDLE             = 4'b0010;
localparam BUZZRING         = 4'b0100;
localparam STOPING_ALARM_DEVICE    = 4'b1000;

// Period of Operation (in clock cycles)
localparam BUZZING_DELAY 	= 100;

// ----------------
// Registers 
// ----------------

reg [3:0] fsm_state = INIT;
reg [6:0] counter_buzzing;
reg [2:0] nth_sensor_triggered;
reg [7:0] total; // used for total number of sensor are triggered 
// ----------------
// RAM  8x8
// ----------------
reg [7:0] RAM [0:7];

integer i;
initial begin
    for(i=0; i<8; i = i+1) begin
        RAM[i] = 0; // initial all data to zero
    end
end


// ----------------
// Controller
// ----------------

always @(posedge clk) begin

    case(fsm_state)

        INIT: begin
            LED <= 0;
            display_data <= 0;
            counter_buzzing <= 0;
            buzzer <=0;
            nth_sensor_triggered <=0;
            total <= 0;
            if (turn == 1) begin
                fsm_state <= IDLE;
            end
        end

        IDLE: begin
            if (turn ==1) begin
                // display some data while idling=> 
                // threshold, threshold from  which sensor, 
                // last measurment, last from  which sensor.
                display_data[7:0]   <=  RAM[0];
                display_data[11:8]  <=  RAM[1];
                display_data[19:12] <=  RAM[2];
                display_data[23:20] <=  RAM[3];
                display_data[30:23] <=  RAM[4];
                 if (pir_sensor_1 >= 50 | pir_sensor_2 >= 50 | pir_sensor_3 >= 50) begin
                     display_data <=0;
                    fsm_state  <=  BUZZRING;
                end 
            end 
            else if (turn == 0) begin
                    fsm_state <= STOPING_ALARM_DEVICE; 
            end
        end

        BUZZRING : begin
            buzzer <= 1;
            if (pir_sensor_1 >= 50) begin
                LED[0] <=1;
                nth_sensor_triggered[0] <=1;
                RAM[2] = pir_sensor_1;
                RAM[3] = 1;
            end
            if (pir_sensor_2 >= 50) begin
                LED[1] <=1;
                nth_sensor_triggered[1] <=1;
                RAM[2] = pir_sensor_2;
                RAM[3] = 2;
            end
            if (pir_sensor_3 >= 50) begin
                LED[2] <=1;
                nth_sensor_triggered[2] <=1;
                RAM[2] = pir_sensor_3;
                RAM[3] = 3;
            end
            
            //  store total nth sensor triggered
            total <= nth_sensor_triggered[0] + nth_sensor_triggered[1] + nth_sensor_triggered[2];

            // store threshold address 0 in RAM, address 1 store from which sensor 
            if (pir_sensor_1 >= pir_sensor_2 & pir_sensor_1 >= pir_sensor_3 & pir_sensor_1 >= RAM[0]) begin
                 RAM[0] <= pir_sensor_1;
                 RAM[1] <= 1;
            end
            if (pir_sensor_2 >= pir_sensor_1 & pir_sensor_2 >= pir_sensor_3 & pir_sensor_2 >= RAM[0]) begin
                 RAM[0] <= pir_sensor_2;
                 RAM[1] <= 2;
            end
            
            if (pir_sensor_3 >= pir_sensor_1 & pir_sensor_3 >= pir_sensor_2 & pir_sensor_3 >= RAM[0]) begin
                 RAM[0] <= pir_sensor_3;
                 RAM[1] <= 3;
            end

            counter_buzzing <= counter_buzzing + 1;
            if (counter_buzzing >= BUZZING_DELAY) begin
                counter_buzzing <= 0;
                fsm_state <= STOPING_ALARM;
            end
            if (stop_alarm == 1 | turn == 0 ) begin
                counter_buzzing <= 0;
                fsm_state <= STOPING_ALARM_DEVICE;
            end 
        end
        STOPING_ALARM_DEVICE: begin
            RAM[4] <= RAM[4] + total; // store number of sensot are triggried
            fsm_state <= INIT;
        end
    endcase
end   

endmodule