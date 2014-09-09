/*
    BubbleCounter is an automated hardened air void parameter determination macro for ImageJ
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
s_properties = s_directory + replace(s_name, ".tif", "_bcProps.txt"); //  name of properties file
s_traverses = s_directory + replace(s_name, ".tif", "_traverses.txt"); //  name of traverses image file

// silent mode supresses messages:
silentMode = false;

//macro "Analyze" {
// everything gets saved in s_properties; the whole of the List object
// only report-bound data is saved in s_results
// individual pixel intensities for the lines are saved in s_traverses
List.clear;

// arrays for dialog controls
// edits made to paste content terminology May 23, 2014
//a_traverseDir = newArray("Horizontal", "Vertical");
a_aggTopSize = newArray("150", "75", "37.5", "25", "19", "12.5", "9.5", "4.75");
a_pasteFracType = newArray("mix design Paste/agg vol. ratio", "Paste vol. fraction", "Agg vol. fraction");
a_analysis = newArray("VF and AC thresholds", "Average threshold", "VF only threshold", "AC only threshold");

// array for values written to results
a_listResults = newArray(
	"nameFile", 
	"traverses", 
	"mmTraversed",
	"mmAir",
	"interceptsAC", 
	"interceptsVF", 
	"lengthMean",
	"specificSurface",
	"fractionVoid",
	"voidFrequency",
	"spacingFactor",
	"pasteToAir",
	"thresholdAC",
	"thresholdVF",
	"analysis"
	);
a_results = newArray(a_listResults.length);

// analysis area selection area dims
var i_a_x,  i_a_y,  i_a_w,  i_a_h;

// arrays for chords
//var a_chordsAC = newArray(); // air content chords
//var a_chordsVF = newArray(); // void frequency chords
//var a_chordLengths = newArray();
//var a_chordCounts = newArray();
// chord length stats
//var lengthMin, lengthMax, lengthMean, lengthStdDev;

//var i_pixelsTraversed, i_pixelsAir, i_interceptsAC, i_interceptsVF, i_mmTraversed, i_mmAir;

	if (File.exists(s_properties)) {
		// white balance is done so processing can be completed
		// the modes for white and black are determined;
		// any pixel having intensity less than or equal to the intensity of the black mode is treated as black
		// any pixel having intensity greater than or equal to the intensity of the white mode is treated as white
		// thresholding - anything greater than the threshold value is white, less than or equal to it is black

		// load up the properties file
		readProps(s_properties);

		// make sure a selection has been made
		h = getHeight();
		getSelectionBounds(i_a_x,  i_a_y,  i_a_w,  i_a_h);

		if (h != i_a_h) {
			// user selected parameters
			i_traverses = parseInt(List.get("traverses"));
			i_thresholdAC = parseInt(List.get("thresholdAC"));
			i_thresholdVF = parseInt(List.get("thresholdVF"));
			f_fractionPasteToAgg = parseFloat(List.get("fractionPasteToAgg"));
			f_fractionPaste = parseFloat(List.get("fractionPaste"));
			f_fractionAgg = parseFloat(List.get("fractionAgg"));
			f_aggTopSize = parseFloat(List.get("aggTopSize"));
			f_fractionAgg = parseFloat(List.get("fractionAgg"));
			f_fractionPasteToAgg = parseFloat(List.get("fractionPasteToAgg"));
			f_fractionPaste = parseFloat(List.get("fractionPaste"));
			s_analysis = List.get("analysis");
			
			if (isNaN(i_traverses)) i_traverses = 57; // number of lines to extract from the analysis area selection
			if (isNaN(i_thresholdAC)) i_thresholdAC = 71; // air content threshold
			if (isNaN(i_thresholdVF)) i_thresholdVF = 52; // void frequency threshold

			if (f_fractionPasteToAgg > 0) {s_pasteFracType = "mix design Paste/agg vol. ratio"; f_pasteFracType = f_fractionPasteToAgg;}
			else if (f_fractionPaste > 0) {s_pasteFracType = "Paste vol. fraction"; f_pasteFracType = f_fractionPaste;}
			else if (f_fractionAgg > 0) {s_pasteFracType = "Agg vol. fraction"; f_pasteFracType = f_fractionAgg;}
			else {s_pasteFracType = "Paste/agg ratio"; f_pasteFracType = 0.00;}

			if (isNaN(f_aggTopSize)) f_aggTopSize = 25.0;

			if (s_analysis == "") s_analysis = "VF and AC thresholds";

			// user interface
			Dialog.create("Automatic Air Void Parameters");
			Dialog.addSlider("Number of traverses:", 19, 150, i_traverses) // 1
			Dialog.addChoice("Aggregate Top Size, mm:", a_aggTopSize, toString(f_aggTopSize)); // 2
			Dialog.addChoice("Paste content determination method:", a_pasteFracType, s_pasteFracType); // 3
			Dialog.addNumber("Value:", f_pasteFracType); // 4
			Dialog.addChoice("Analysis to Perform:", a_analysis, s_analysis); // 5
			Dialog.addNumber("Air content threshold", i_thresholdAC); // 6
			Dialog.addNumber("Void frequency threshold", i_thresholdVF); // 7
			Dialog.show();

			// apparently dialog values cannot be read by a function:
			i_traverses = Dialog.getNumber(); // 1
			f_aggTopSize = Dialog.getChoice(); // 2
			s_pasteFracType = Dialog.getChoice(); // 3
			f_pasteFracType = Dialog.getNumber(); // 4
			s_analysis = Dialog.getChoice(); // 5
			i_thresholdAC = Dialog.getNumber(); // 6
			i_thresholdVF = Dialog.getNumber(); // 7

			if (s_pasteFracType == "mix design Paste/agg vol. ratio" && f_pasteFracType > 0) {
				f_fractionPasteToAgg = f_pasteFracType;
				f_fractionPaste = NaN;
				f_fractionAgg = NaN;
			}
			else if (s_pasteFracType == "Paste vol. fraction" && f_pasteFracType > 0) {
				f_fractionPaste = f_pasteFracType;
				f_fractionPasteToAgg = NaN;
				f_fractionAgg = NaN;
			}
			else if (f_pasteFracType > 0) {
				f_fractionPasteToAgg = NaN;
				f_fractionPaste = NaN;
				f_fractionAgg = f_pasteFracType;
			}

			i_avgThreshold = round((i_thresholdAC + i_thresholdVF) / 2);

			// stretch the image
			setMinAndMax(List.get("modeBlack"), List.get("modeWhite"));
			run("Apply LUT");
			// select i_traverses lines from the analysis area and store the intensities of each of their pixels
			i_interval = floor(i_a_h / i_traverses);

			// using the Array.print() method is significantly faster than the a_to_csv option
			for (i = 0; i < i_traverses; i++) {
				makeRectangle(i_a_x, i_a_y + i * i_interval, i_a_w, 1);
				a_intensity = getProfile();
				Array.print(a_intensity);
			}
			// save the pixel intensity array as a text tif image
			saveAs("Text", s_traverses);
			run("Close");

			// set properties in the List object
			List.set("boundsAnalysisArea", i_a_x + "," + i_a_y + "," + i_a_w + "," + i_a_h);
			List.set("nameFile", s_name);
			List.set("traverses", i_traverses);
			List.set("thresholdAC", i_thresholdAC)
			List.set("thresholdVF", i_thresholdVF)
			List.set("fractionAgg", f_fractionAgg);
			List.set("fractionPasteToAgg", f_fractionPasteToAgg);
			List.set("fractionPaste", f_fractionPaste);
			List.set("analysis", s_analysis);
			List.set("aggTopSize", f_aggTopSize);
			// write to the properties file so values are available to processTraverses.ijm
			writeProps();

			// process traverses - processTraverses.ijm populates the List object and returns it as a string
			List.setList(runMacro(getDirectory("macros") + "BubbleCounter" + File.separator + "processTraverses.ijm", s_traverses));

			// write the List object to the properties file
			writeProps();

			// build the results array
			populateResults(a_results);

			//display the results
			if (!silentMode) showMessage(buildResultsForDisplay());

			// save results to file
			f = File.open(s_results);
			print(f, delimitArray(a_results, ","));
			File.close(f);

			// revert the image so the original is preserved
			run("Revert");
		}

		else {
			// need to make a selection
			showMessage("Please select an area to analyze using the rectangular selection tool.");
		}
	}

	else {
		// need to run the white balance macro before processing
		showMessage("The white balance card has not been analyzed for this image. Run the white balance macro and then attempt analysis.");
	}
//} //end macro analyze

// reads the properties file
function readProps(s_properties) {
	List.setList(File.openAsString(s_properties));
} // end function getProps

// writes the current List object to the properties file
function writeProps() {
		f = File.open(s_properties);
		print(f, List.getList);
		File.close(f);
} // end function writeProps

// build the results array
function populateResults(a) {
	for (i = 0; i < a_listResults.length; i++) {
		a[i] = List.get(a_listResults[i]);
	}
} // end function populateResults


function buildResultsForDisplay() {
	s = "";
	for (i = 0; i < a_listResults.length; i++) {
		s += a_listResults[i] + " = " + a_results[i] + "\n";
	}
	return s;
}

function delimitArray(a, delimitter) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + delimitter;

	s = s + a[a.length -1];

	return s;
}
