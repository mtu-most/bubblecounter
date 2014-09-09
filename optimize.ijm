/*
    optimize is an ImageJ macro that optimizes the thresholds used for air content and void frequency determination
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

s_directory = getDirectory("Choose a Directory Containing Analyzed Images");
a_filesAll = getFileList(s_directory);
s_fileACResults = s_directory + "optimumAC.txt";
s_fileVFResults = s_directory + "optimumVF.txt";

if (File.exists(s_directory + "manualAVP.txt")) {
	// delete existing results files
	del = File.delete(s_fileACResults);
	del = File.delete(s_fileVFResults);

	// array of List keys written to results
	a_ACResults = newArray(
		"nameFileOriginal",
		"traverses",
		"modeBlack",
		"modeWhite",
		"thresholdAC",
		"fractionVoid"
		);

	a_VFResults = newArray(
		"nameFileOriginal",
		"traverses",
		"modeBlack",
		"modeWhite",
		"thresholdVF",
		"voidFrequency"
		);
	
	a_ACresults =  newArray(a_ACResults.length);
	a_VFresults =  newArray(a_VFResults.length);

	//write headers to the files
	headerAC = delimitArray(a_ACResults, ",");
	headerAC += ",Target value";
	headerVF = delimitArray(a_VFResults, ",");
	headerVF += ",Target value";
	File.append(headerAC, s_fileACResults);
	File.append(headerVF, s_fileVFResults);

	// make a table to print results to
	s_tableAC = "[Optimum Air Content]";
	run("Table...", "name=" + s_tableAC);
	print(s_tableAC, "\\Headings:\t" + replace(headerAC, ",", "\t"));

	s_tableVF = "[Optimum Void Frequency]";
	run("Table...", "name=" + s_tableVF);
	print(s_tableVF, "\\Headings:\t" + replace(headerVF, ",", "\t"));

	// open and parse manualAVP.txt, a comma delimited list of filename, air content (fraction) and void frequency

	a_manualAVP = split(File.openAsString(s_directory + "manualAVP.txt"), '\n');

	showStatus("Optimizing...");

	for (file = 0; file < a_filesAll.length; file++) {
		if (indexOf(a_filesAll[file], "_traverses.txt") > 0) {
			s_originalFileName = replace(a_filesAll[file], "_traverses.txt", ".tif");
			a_currentAVP = lookupManualAVP(s_originalFileName);

			if (!isNaN(a_currentAVP)) {
				// build the complete file name
				s_traverses = s_directory + a_filesAll[file];

				// perform a binary search for the optimum air content threshold
				// the routine will also tighten the range of thresholds for finding optimum VF threshold
				a_optThreshold = optimumThreshold(s_traverses, "fractionVoid", parseFloat(a_currentAVP[1]), 1, 254);

				//write the results to the table and file
				reportResults(a_ACResults, a_currentAVP[1], s_tableAC, s_fileACResults);
		
				// find the optimum VF threshold
				a_opt_VFThreshold = optimumThreshold(s_traverses, "voidFrequency", parseFloat(a_currentAVP[2]), 1, 254);
				reportResults(a_VFResults, a_currentAVP[2], s_tableVF, s_fileVFResults);
			}
			else {
				// append a line indicating the manual AVP values couldn't be found
				s_notFound = "No manual AVP results found for " + s_originalFileName;
				File.append(s_notFound, s_fileACResults);
				File.append(s_notFound, s_fileACResults);
				print(s_tableAC, s_notFound);
				print(s_tableVF, s_notFound);
			}
		}
		showProgress(file / a_filesAll.length);
	}

	showStatus("");

	showMessage("Optimization Complete");
}
else
	showMessage("Create manualAVP.txt with manually determined AVPs and run again.");
/**********************************************************

functions

**********************************************************/

function reportResults(resultsArray, target, table, file) {
	s_results = "";
	for (j = 0; j < resultsArray.length; j++)
		s_results += List.get(resultsArray[j]) + ",";
	s_results += target;
	// save the results from the just processed file
	File.append(s_results, file);
	// print to the log window so progress is indicated
	print(table, replace(s_results, ",", "\t"));
}

function optimumThreshold(s_traverses, parameter1, target1, i_minThreshold1, i_maxThreshold1) {
	while (i_maxThreshold1 - i_minThreshold1 > 1) {
		i_testThreshold = floor((i_maxThreshold1 + i_minThreshold1) / 2);
		List.setList(runMacro(getDirectory("macros") + "BubbleCounter" + File.separator + "processTraverses.ijm", s_traverses + "::FLAG::optimize:" + toString(i_testThreshold)));
		f_parameter1 = parseFloat(List.get(parameter1));
		if (isNaN(f_parameter1)) return false;
		if (target1 - f_parameter1 < 0)
			i_minThreshold1 = i_testThreshold;
		else
			i_maxThreshold1 = i_testThreshold;
	}
	return i_maxThreshold1;
}

function lookupManualAVP(s_fileName) {
	i = 0;
	found = false;
	a_line = false;
	while (i < a_manualAVP.length && !found) {
		a_line = split(a_manualAVP[i], ",");
		if (a_line.length > 0) found = (toLowerCase(a_line[0]) == toLowerCase(s_fileName));
		i++;
	}
	if (found)
		return a_line;
	else
		return 0/0; // return NaN
}

function delimitArray(a, delimitter) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + delimitter;

	s = s + a[a.length -1];

	return s;
}

