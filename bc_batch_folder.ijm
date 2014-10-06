/*
    bc_batch_folderis an ImageJ macro that processes traverse file created during earlier analysis in a batch-wise fashion
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

// process all traverse files found in a supplied directory using the values selected by the user

// get the directory where the files are located
s_directory = getDirectory("Choose a Directory Containing Analyzed Images");
s_fileSummaryResults = s_directory + "summaryResults.txt";

// make a file list
a_filesAll = getFileList(s_directory);

// array for values written to results
a_listResults = newArray(
	"nameFileOriginal",
	"analysis",
	"thresholdAC",
	"thresholdVF",
	"mmTraversed",
	"mmAir",
	"interceptsVF", 
	"lengthMean",
	"specificSurface",
	"voidFrequency",
	"fractionVoid",
	"spacingFactor",
	"pasteToAir",
	"fractionAgg",
	"fractionPaste",
	"fractionPasteToAgg"
	);
a_results = newArray(a_listResults.length);

	// delete existing results files
	del = File.delete(s_fileSummaryResults);

	// make a table to print results to
	s_tableResults = "[Summary Results]";
	run("Table...", "name=" + s_tableResults);
	header = delimitArray(a_listResults, ",");
	print(s_tableResults, header);

// setup input array
a_analysis = newArray("VF and AC thresholds", "Average threshold", "VF only threshold", "AC only threshold");

// get the values to use for processing
Dialog.create("Automatic Air Void Parameters");
Dialog.addChoice("Analysis to Perform:", a_analysis); // 1
Dialog.addNumber("Air content threshold", 99); // 2
Dialog.addNumber("Void frequency threshold", 99); // 3
Dialog.show();

s_analysis = Dialog.getChoice(); // 1
i_thresholdAC = Dialog.getNumber(); // 2
i_thresholdVF = Dialog.getNumber(); // 3
f_fractionAgg = NaN
f_fractionPaste = NaN
f_fractionPasteToAgg = 0.3


// counter for files processed
i_files_processed = 0;

// iterate through files and process
for (file = 0; file < a_filesAll.length; file++) {
	// see if it's a properties file
	if (indexOf(a_filesAll[file], "_bcProps.txt") > 0) {
		// see if the traverse file exists
		s_traverses = s_directory + replace(a_filesAll[file], "_bcProps.txt","_traverses.txt");
		if (File.exists(s_traverses)) {
			// populate the List object
			readProps(s_directory + a_filesAll[file]);

			// set unpopulated list items
			List.set("thresholdAC", i_thresholdAC)
			List.set("thresholdVF", i_thresholdVF)
			List.set("analysis", s_analysis);
			List.set("fractionAgg", f_fractionAgg);
			List.set("fractionPaste", f_fractionPaste);
			List.set("fractionPasteToAgg", f_fractionPasteToAgg);
			// write to the properties file so values are available to processTraverses.ijm
			writeProps(s_directory + a_filesAll[file]);

			// process traverses - processTraverses.ijm populates the List object and returns it as a string
			List.setList(runMacro(getDirectory("macros") + "BubbleCounter" + File.separator + "processTraverses.ijm", s_traverses));

			// write the List object to the properties file
			writeProps(s_directory + a_filesAll[file]);

			// build the results array
			populateResults(a_results);

			i_files_processed++;
			// save results to file
			s_results = s_directory + replace(List.get("nameFileOriginal"), ".tif", "_bcResults.txt");
			f = File.open(s_results);
			print(f, delimitArray(a_results, ","));
			File.close(f);

			//write to table and summary file
			print(s_tableResults, delimitArray(a_results, ","));
			save(s_fileSummaryResults);

		}
	}
}


showMessage("Processed " + i_files_processed + " files.");


/**********************************************************

functions

**********************************************************/




// reads the properties file
function readProps(s_properties) {
	List.setList(File.openAsString(s_properties));
} // end function getProps


function writeProps(s_properties) {
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

function delimitArray(a, delimitter) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + delimitter;

	s = s + a[a.length -1];

	return s;
}




