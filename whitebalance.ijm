/*
    whitebalance is an ImageJ macro that determines the modes for black and white intensities for a selected area.
    Copyright (C) 2014 Gerald Anzalone

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

// current image location and name
var s_directory, s_name, s_results, s_properties, s_traverses;
s_directory = getInfo("image.directory");
s_name = getInfo("image.filename");
s_results = s_directory + replace(s_name, ".tif", "_bcResults.txt"); //  name of results file
s_properties = s_directory + replace(s_name, ".tif", "_bcProps.txt"); //  name of results file
s_traverses = s_directory + replace(s_name, ".tif", "_traverses.txt"); //  name of traverses image file

// silent mode supresses messages:
silentMode = false;

macro "whiteBalance" {
	// vars for histogram data
	ibins = 256;
	i_modeBlack = -1;
	i_modeWhite = -1;
	i_countsBlack = -1;
	i_countsWhite = -1;
	// white balance card selection area dims
	var i_wb_x,  i_wb_y,  i_wb_w,  i_wb_h;

	// everything will be stored in IJ's List object, clear it
	List.clear;

	// make sure a region is selected
	h = getHeight();
	getSelectionBounds(i_wb_x,  i_wb_y,  i_wb_w,  i_wb_h);

	if (h != i_wb_h) {
		// check if wb file already exists
		if (File.exists(s_properties)) {
			showMessageWithCancel("File Exists", "The white balance has already been determined for the image. Clicking OK will overwrite existing file.");
		}

		getPixelSize(unit, pw, ph, pd);
		
		if (unit == "inches") {
			unit = "microns";
			pw = pw * 25400;
			ph = ph * 25400;
		}


		// ask the user if the scanner resolution and pixel resolution matches, added July 14, 2016 by Tianqing and Junbo, because sometimes the resolution data
		// read by WhiteBalance is messed up.
		
		f_converter = 39.37; // 1 dpi = 39.37 dpm
		i_dpi = 25400 / pw;
		i_dpm = round(f_converter * i_dpi);

		Dialog.create("Scanner Information");
		Dialog.addMessage("Scanner resolution: \n" + i_dpi + " dpi\n" + i_dpm + " dpm\n" + "Pixel Resolution: " + pw + " X " + ph + " microns\nIf the information above is correct, click OK;\nif the information above is not correct, enter the correct value below: ");
		Dialog.addNumber("Scanner Resolution (dpi): ", i_dpi); // 1
		Dialog.show();

		i_dpi = Dialog.getNumber(); // 1
	
		pw = 25400 / i_dpi;
		ph = pw;
		unit = "microns";

		// get the histogram for the selection
		getHistogram(i_histValues, i_histCounts, ibins);
		// iterate through the histogram data from top and bottom and ID modes for black and white
		for (i = 0; i < floor(ibins / 2); i++) {
			if (i_histCounts[i] > i_countsBlack) {
				i_countsBlack = i_histCounts[i];
				i_modeBlack = i_histValues[i];
			}

			if (i_histCounts[255 - i] > i_countsWhite) {
				i_countsWhite = i_histCounts[255 - i];
				i_modeWhite = i_histValues[255 - i];
			}
		}


		List.set("nameFileOriginal", s_name);
		List.set("unit", unit);
		List.set("pixelWidth", pw);
		List.set("pixelHeight", ph);
		List.set("pixelDepth", pd);
		List.set("boundsWhiteBalance", i_wb_x + "," + i_wb_y + "," + i_wb_w + "," + i_wb_h);
		List.set("modeBlack", i_modeBlack);
		List.set("modeWhite", i_modeWhite);
		// List.set("ChordCutoff", i_chordCutoff);

		// write the List object to a file
		writeProps();

		if (!silentMode) showMessage("The white balance has been determined:\nBlack mode: " + i_modeBlack + "\nWhite mode: " + i_modeWhite);
	}
	else {
		showMessage("Select a region of the white balance card and rerun the macro.");
	}
} // end macro WhiteBalance

macro "analyze" {

}

// writes the current List object to the properties file
function writeProps() {
		f = File.open(s_properties);
		print(f, List.getList);
		File.close(f);
}

// creates a comma separated value string from the values in the supplied array:
function a_to_csv(a) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + ",";

	s = s + a[a.length -1];

	return s;
}


