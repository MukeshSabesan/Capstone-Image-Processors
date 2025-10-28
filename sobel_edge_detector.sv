
// Sobel Edge Detection Module
module sobel_edge_detector #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [7:0]  pixel_in,
    input  logic        pixel_valid,
    output logic [7:0]  pixel_out,
    output logic        pixel_out_valid,
    output logic        done
);

    // Line buffers for 3x3 window (need 2 lines + current)
    logic [7:0] line_buffer1 [0:IMG_WIDTH-1];
    logic [7:0] line_buffer2 [0:IMG_WIDTH-1];
    logic [7:0] current_line [0:IMG_WIDTH-1];
    
    // 3x3 window
    logic [7:0] window [0:2][0:2];
    
    // Counters
    logic [15:0] pixel_count;
    logic [15:0] col_count;
    logic [15:0] row_count;
    
    // Sobel computation
    logic signed [10:0] gx, gy;
    logic [15:0] magnitude;
    logic [7:0] edge_value;
    
    // State
    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        DONE_STATE
    } state_t;
    state_t state;
    
    // Sobel kernels
    // Gx: [-1  0  1]    Gy: [-1 -2 -1]
    //     [-2  0  2]         [ 0  0  0]
    //     [-1  0  1]         [ 1  2  1]
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pixel_count <= 0;
            row_count <= 0;
            col_count <= 0;
            done <= 0;
            pixel_out_valid <= 0;
            pixel_out <= 0;
            
            // Clear buffers
            for (int i = 0; i < IMG_WIDTH; i++) begin
                line_buffer1[i] <= 0;
                line_buffer2[i] <= 0;
                current_line[i] <= 0;
            end
            
            for (int i = 0; i < 3; i++)
                for (int j = 0; j < 3; j++)
                    window[i][j] <= 0;
                    
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= PROCESSING;
                        pixel_count <= 0;
                        row_count <= 0;
                        col_count <= 0;
                        done <= 0;
                    end
                    pixel_out_valid <= 0;
                end
                
                PROCESSING: begin
                    if (pixel_valid) begin
                        // Store pixel in current line
                        current_line[col_count] <= pixel_in;
                        
                        // Update 3x3 window
                        if (col_count >= 2) begin
                            window[0][0] <= line_buffer2[col_count-2];
                            window[0][1] <= line_buffer2[col_count-1];
                            window[0][2] <= line_buffer2[col_count];
                            
                            window[1][0] <= line_buffer1[col_count-2];
                            window[1][1] <= line_buffer1[col_count-1];
                            window[1][2] <= line_buffer1[col_count];
                            
                            window[2][0] <= current_line[col_count-2];
                            window[2][1] <= current_line[col_count-1];
                            window[2][2] <= pixel_in;
                        end
                        
                        // Compute Sobel (only when we have valid 3x3 window)
                        if (row_count >= 2 && col_count >= 2) begin
                            // Gx computation
                            gx = -$signed({3'b0, window[0][0]}) + $signed({3'b0, window[0][2]})
                                 -2*$signed({3'b0, window[1][0]}) + 2*$signed({3'b0, window[1][2]})
                                 -$signed({3'b0, window[2][0]}) + $signed({3'b0, window[2][2]});
                            
                            // Gy computation
                            gy = -$signed({3'b0, window[0][0]}) - 2*$signed({3'b0, window[0][1]}) - $signed({3'b0, window[0][2]})
                                 +$signed({3'b0, window[2][0]}) + 2*$signed({3'b0, window[2][1]}) + $signed({3'b0, window[2][2]});
                            
                            // Approximate magnitude: |Gx| + |Gy| (faster than sqrt)
                            magnitude = (gx < 0 ? -gx : gx) + (gy < 0 ? -gy : gy);
                            
                            // Clamp to 255
                            edge_value = (magnitude > 255) ? 8'd255 : magnitude[7:0];
                            
                            pixel_out <= edge_value;
                            pixel_out_valid <= 1;
                        end else begin
                            pixel_out_valid <= 0;
                        end
                        
                        // Update counters
                        col_count <= col_count + 1;
                        pixel_count <= pixel_count + 1;
                        
                        // End of row
                        if (col_count == IMG_WIDTH - 1) begin
                            col_count <= 0;
                            row_count <= row_count + 1;
                            
                            // Shift line buffers
                            for (int i = 0; i < IMG_WIDTH; i++) begin
                                line_buffer2[i] <= line_buffer1[i];
                                line_buffer1[i] <= current_line[i];
                            end
                        end
                        
                        // End of image
                        if (pixel_count == IMG_WIDTH * IMG_HEIGHT - 1) begin
                            state <= DONE_STATE;
                            done <= 1;
                        end
                    end else begin
                        pixel_out_valid <= 0;
                    end
                end
                
                DONE_STATE: begin
                    pixel_out_valid <= 0;
                    if (!start) begin
                        state <= IDLE;
                        done <= 0;
                    end
                end
            endcase
        end
    end

endmodule

