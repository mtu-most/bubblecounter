// process all traverse files found in a supplied directory using the values selected by the user

// get the directory where the files are located
s_directory = getDirectory("Choose a Directory Containing Analyzed Images");

// make a file list
a_filesAll = getFileList(s_directory);

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
	"thresholdAC",
	"thresholdVF",
	"analysis"
	);
a_results = newArray(a_listResults.length);

// setup input array
a_analysis = newArray("Individual threshold", "Average threshold", "VF only threshold", "AC only threshold");

// get the values to use for processing
Dialog.create("Automatic Air Void Parameters");
Dialog.addChoice("Analysis to Perform:", a_analysis); // 1
Dialog.addNumber("Air content threshold", 99); // 2
Dialog.addNumber("Void frequency threshold", 99); // 3
Dialog.show();

s_analysis = Dialog.getChoice(); // 1
i_thresholdAC = Dialog.getNumber(); // 2
i_thresholdVF = Dialog.getNumber(); // 3

// counter for files processed
i_files_processed = 0;

// iterate through files and process
for (file = 0; file < a_filesAll.length; file++) {
	// see if it's a properties file
	if (indexOf(a_filesAll[file], "_bcprops.txt") > 0) {
		// see if the traverse file exists
		s_traverses = s_directory + replace(a_filesAll[file], "_bcprops.txt","_traverses.txt");
		if (File.exists(s_traverses)) {
			// populate the List object
			readProps(s_directory + a_filesAll[file]);

			// set unpopulated list items
			List.set("thresholdAC", i_thresholdAC)
			List.set("thresholdVF", i_thresholdVF)
			List.set("analysis", s_analysis);
			// write to the properties file so values are available to processTraverses.ijm
			writeProps(s_directory + a_filesAll[file]);

			// process traverses - processTraverses.ijm populates the List object and returns it as a string
			List.setList(runMacro(getDirectory("macros") + "BubbleCounter" + File.separator + "processTraverses.ijm", s_traverses));

			// write the List object to the properties file
			writeProps(s_directory + a_filesAll[file]);

			i_files_processed++;
			// save results to file
			s_results = s_directory + replace(List.get("nameFileOriginal"), ".tif", "_bcResults.txt");
			f = File.open(s_results);
			print(f, delimitArray(a_results, ","));
			File.close(f);

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


function delimitArray(a, delimitter) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + delimitter;

	s = s + a[a.length -1];

	return s;
}
