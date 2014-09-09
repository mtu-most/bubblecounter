/**********************************************************

Aggregate fraction point count

1) Scan image at 3175 dpi, color to better distinguish aggregate, tiff
2) Open image in ImageJ
3) Select representative rectangular area to sample
4) Run macro
5) Results displayed in dialog box and saved as a csv file in the same folder as the original image

 ***CLICKING CANCEL during the count will result in irretrievable loss of all collected data***

**********************************************************/
var s_directory, s_name, s_results, s_properties, s_traverses;
s_directory = getInfo("image.directory");
s_name = getInfo("image.filename");
s_results = s_directory + replace(s_name, ".tif", "_bcPtCnt.txt"); //  name of results file

i_samples = 500; // number of sample points - this is a target, may not actually produce the value set
i_aggregate = 0; // counter for aggregate points
i_current = 1; // sample point counter
arrow_color = "yellow"; // the color of the marker arrow

// analysis area selection area dims
var i_a_x,  i_a_y,  i_a_w,  i_a_h;

h = getHeight();
getSelectionBounds(i_a_x,  i_a_y,  i_a_w,  i_a_h);

// make sure an area has been selected
if (h != i_a_h) {
	// get the area of the selection and divide by the number of samples to establish roi area
	i_selection = i_a_w * i_a_h;
	i_roi_area = floor(i_selection / i_samples);
	i_roi_edge = floor(sqrt(i_roi_area));
	if (i_roi_edge%2 > 0) i_roi_edge += 1; // make the edge length even so that the arrow is nicely centered
	i_x_steps = floor(i_a_w / i_roi_edge); // the number of sample steps in a row
	i_y_steps = floor(i_samples / i_x_steps); // the number of sample steps in a column

	// iterate through the sample locatins and collect data from the user
	for (var y_step = 0; y_step < i_y_steps; y_step++) {
		for (var x_step = 0; x_step < i_x_steps; x_step++) {
			x = i_a_x + x_step * i_roi_edge; // the current x-position
			y = i_a_y + y_step * i_roi_edge; // the current y-position
			// if this is the very first sample point, draw an arrow in the center of the selection area
			if (y_step + x_step == 0) {
				// draw an arrow overlay that will be reused:
				makeArrow(x + i_roi_edge / 2, y + 3 * i_roi_edge / 4, x + i_roi_edge / 2, y + i_roi_edge / 2, "Filled Small");
				Roi.setStrokeColor(arrow_color);
				Roi.setStrokeWidth(5);
				Overlay.addSelection();
			}
			else {
				// move the arrow overlay to the current position
				Overlay.moveSelection(0, x + i_roi_edge / 2, y + i_roi_edge / 2);
			}
			// select a rectangle prompt the user if arrow point over aggregate
			makeRectangle(x - 0.5 * i_roi_edge, y - 0.5 * i_roi_edge, 2 * i_roi_edge, 2 * i_roi_edge);
			run("To Selection");
			if(getBoolean("Region " + i_current + "/" + i_samples + "\n" + i_aggregate / i_current + " aggregate fraction\n \nIs the arrow point on aggregate?"))
				i_aggregate += 1;
			i_current++;
		}
	}

	// write the results to the results file and prompt the user with aggregate fraction
	s_report = "Aggregate point count results for " + s_name + "\n";
	s_report += "Total points," + i_samples + "\n";
	s_report += "Total points on aggregate," + i_aggregate + "\n";
	s_report += "Aggregate fraction," + i_aggregate / (i_current - 1);
	f = File.open(s_results);
	print(f, s_report);
	File.close(f);

	showMessage("Aggregate fraction = " + i_aggregate / (i_current - 1) + "\n Results stored to " + s_results);
}
else {
	showMessage("Select a rectangular analysis area and rerun the macro.");
}
