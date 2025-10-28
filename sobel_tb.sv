//=====================================================
// Sobel Edge Detection Testbench (Fixed Auto-Finish)
//=====================================================
module sobel_tb;
    parameter IMG_WIDTH  = 422;
    parameter IMG_HEIGHT = 413;
    parameter CLK_PERIOD = 10;
    
    logic clk;
    logic rst_n;
    logic start;
    logic [7:0] pixel_in;
    logic pixel_valid;
    logic [7:0] pixel_out;
    logic pixel_out_valid;
    logic done;
    
    // Test image (8x8 gradient + pattern)
   logic [7:0] test_image [0:IMG_HEIGHT-1][0:IMG_WIDTH-1]; 
    
   logic [7:0] output_image [0:IMG_HEIGHT-3][0:IMG_WIDTH-3];
    
    //=====================================================
    // Task: Load image from text file
    //=====================================================
    task load_image_from_file(input string filename);
        int file_handle;
        int scan_result;
        int pixel_value;
        int file_width, file_height;
        int i, j;
        
        file_handle = $fopen(filename, "r");
        
        
        $display("?? Loading image from: %s", filename);
        
        // Read dimensions from header
        scan_result = $fscanf(file_handle, "%d %d", file_height, file_width);
        if (scan_result != 2) begin
            $display("ERROR: Cannot read image dimensions");
            $fclose(file_handle);
            return;
        end
        
        $display("   File dimensions: %0dx%0d", file_height, file_width);
        
        // Check dimensions match
        if (file_height != IMG_HEIGHT || file_width != IMG_WIDTH) begin
            $display("ERROR: Image size mismatch!");
            $display("Expected: %0dx%0d, Got: %0dx%0d", 
                     IMG_HEIGHT, IMG_WIDTH, file_height, file_width);
            $display("   Update IMG_WIDTH and IMG_HEIGHT parameters!");
            $fclose(file_handle);
            $finish;
        end
        
        // Read pixel data into test_image array
        for (i = 0; i < IMG_HEIGHT; i++) begin
            for (j = 0; j < IMG_WIDTH; j++) begin
                scan_result = $fscanf(file_handle, "%d", pixel_value);
                if (scan_result != 1) begin
                    $display("ERROR: Failed to read pixel at (%0d,%0d)", i, j);
                    $fclose(file_handle);
                    $finish;
                end
                test_image[i][j] = pixel_value[7:0];  // ? This updates test_image!
            end
        end
        
        $fclose(file_handle);
        $display("Image loaded into test_image array: %0dx%0d pixels", IMG_HEIGHT, IMG_WIDTH);
        
        // Show some sample pixels to verify
        $display("   Sample pixels (first 8):");
        $write("   ");
        for (j = 0; j < 8 && j < IMG_WIDTH; j++)
            $write("%3d ", test_image[0][j]);
        $display("\n");
    endtask
    
    //=====================================================
    // Task: Save output image to text file
    //=====================================================
    /*task save_output_to_file(input string filename);
        int file_handle;
        int i, j;
        int out_h, out_w;
        
        out_h = IMG_HEIGHT - 2;
        out_w = IMG_WIDTH - 2;
        
        file_handle = $fopen(filename, "w");
        if (file_handle == 0) begin
            $display("? ERROR: Cannot create file '%s'", filename);
            return;
        end
        
        $display("?? Saving edge-detected image to: %s", filename);
        
        // Write dimensions
        $fwrite(file_handle, "%0d %0d\n", out_h, out_w);
        
        // Write pixel values
        for (i = 0; i < out_h; i++) begin
            for (j = 0; j < out_w; j++) begin
                $fwrite(file_handle, "%0d", output_image[i][j]);
                if (j < out_w - 1)
                    $fwrite(file_handle, " ");
            end
            $fwrite(file_handle, "\n");
        end
        
        $fclose(file_handle);
        $display("? Output saved: %0dx%0d pixels\n", out_h, out_w);
    endtask */

    task save_output_to_file(input string filename);
       int file_handle;
       int i, j;
       int out_h, out_w;
    
       out_h = IMG_HEIGHT - 2;
       out_w = IMG_WIDTH - 2;
    
       file_handle = $fopen(filename, "w");
       if (file_handle == 0) begin
           $display("ERROR: Cannot create file '%s'", filename);
           return;
       end
    
    // Write dimensions header
       $fwrite(file_handle, "%0d %0d\n", out_h, out_w);
    
    // Write pixel values
       for (i = 0; i < out_h; i++) begin
           for (j = 0; j < out_w; j++) begin
             if (j > 0)
                $fwrite(file_handle, " ");  // Space BEFORE (except first)
                $fwrite(file_handle, "%0d", output_image[i][j]);
          end
        $fwrite(file_handle, "\n");  // Newline after each row
       end
    
    // IMPORTANT: Close file BEFORE any display
    $fclose(file_handle);
    
    // Now display to console (won't affect file)
    $display("Output saved: %0d x %0d pixels", out_h, out_w);
    endtask
    
    //=====================================================
    // DUT Instantiation
    //=====================================================
    sobel_edge_detector #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .pixel_out(pixel_out),
        .pixel_out_valid(pixel_out_valid),
        .done(done)
    );
    
    //=====================================================
    // Clock generation
    //=====================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //=====================================================
    // Output capture
    //=====================================================
    int out_row = 0, out_col = 0;
    int processed_count = 0;
    int total_pixels = (IMG_WIDTH - 2) * (IMG_HEIGHT - 2);
    logic output_complete = 0;
    
    always_ff @(posedge clk) begin
        if (pixel_out_valid) begin
            output_image[out_row][out_col] <= pixel_out;
            processed_count++;
            
            $display("[%0t] pixel_out[%0d][%0d] = %0d", 
                     $time, out_row, out_col, pixel_out);
            
            out_col++;
            if (out_col >= IMG_WIDTH - 2) begin
                out_col = 0;
                out_row++;
            end
            
            // Check if all outputs captured
            if (processed_count >= total_pixels - 1) begin
                output_complete = 1;
                $display("\n? All %0d output pixels captured!", total_pixels);
            end
        end
    end

    //=====================================================
    // Detect when DUT finishes
    //=====================================================
    always_ff @(posedge clk) begin
      if (done && !output_complete) begin
        output_complete = 1;
        $display("\n? DUT signaled done at time %0t", $time);
      end
    end

    
    //=====================================================
    // Test sequence
    //=====================================================
    initial begin
        $display("Starting Sobel Edge Detection Simulation...");
        $display("Expected output pixels: %0d\n", total_pixels);

	load_image_from_file("flower_input.txt");
    	$display("Image loaded successfully.\n");
        
        // Initialize
        rst_n = 0;
        start = 0;
        pixel_in = 0;
        pixel_valid = 0;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        
        // Start processing
        start = 1;
        pixel_valid = 1;
        
        // Feed image pixels
        for (int i = 0; i < IMG_HEIGHT; i++) begin
            for (int j = 0; j < IMG_WIDTH; j++) begin
                pixel_in = test_image[i][j];
                @(posedge clk);
            end
        end
        
        pixel_valid = 0;
        start = 0;
        
        // Wait for all outputs to be captured
        wait(output_complete);
        
        // Give a few more cycles for any pending outputs
        repeat(5) @(posedge clk);
        
        // Display results
        show_results();
        
        // Finish simulation
        $display("\n? Simulation completed successfully!");
	// Save the processed output to a file
    	save_output_to_file("sobel_output.txt");

        $finish;
    end
    
    //=====================================================
    // Display results (task)
    //=====================================================
    task show_results;
	// Statistics
        int max_edge;
        int min_edge;
        real avg_edge;
        int edge_count;

        $display("\n=== Input Image (Values) ===");
        for (int i = 0; i < IMG_HEIGHT; i++) begin
            for (int j = 0; j < IMG_WIDTH; j++)
                $write("%3d ", test_image[i][j]);
            $display("");
        end

        $display("\n=== Input Image (Visualized) ===");
        for (int i = 0; i < IMG_HEIGHT; i++) begin
            for (int j = 0; j < IMG_WIDTH; j++) begin
                $write("%s", test_image[i][j] > 128 ? "?" : " ");
	    end
            $display("");
        end

        $display("\n=== Output Image (Edge Values) ===");
        for (int i = 0; i < IMG_HEIGHT - 2; i++) begin
            for (int j = 0; j < IMG_WIDTH - 2; j++) begin
		if (output_image[i][j] == "x") output_image[i][j] = 0;
                $write("%3d ", output_image[i][j]);
	    end
            $display("");
        end

        $display("\n=== Output Image (Visualized) ===");
        for (int i = 0; i < IMG_HEIGHT - 2; i++) begin
            for (int j = 0; j < IMG_WIDTH - 2; j++) begin
                $write("%s", output_image[i][j] > 128 ? "?" : " ");
	    end
            $display("");
        end
        
        
        for (int i = 0; i < IMG_HEIGHT - 2; i++) begin
            for (int j = 0; j < IMG_WIDTH - 2; j++) begin
                if (output_image[i][j] > max_edge) max_edge = output_image[i][j];
                if (output_image[i][j] < min_edge) min_edge = output_image[i][j];
                avg_edge += output_image[i][j];
                if (output_image[i][j] > 128) edge_count++;
            end
        end
        avg_edge /= ((IMG_HEIGHT-2) * (IMG_WIDTH-2));
	
	

        $display("\n=== Edge Statistics ===");
        $display("Total pixels: %0d", total_pixels);
        $display("Strong edges (>128): %0d (%.1f%%)", edge_count, 100.0*edge_count/total_pixels);
        $display("Min edge value: %0d", min_edge);
        $display("Max edge value: %0d", max_edge);
        $display("Avg edge value: %.2f", avg_edge);

	if (processed_count >= total_pixels) output_complete = 1;
    endtask
    
    //=====================================================
    // Safety timeout
    //=====================================================
    //=====================================================
    initial begin
        $dumpfile("sobel_tb.vcd");
        $dumpvars(0, sobel_tb);
    end

endmodule
