/*
    processTraverses is the working part of BubbleCounter. It's the ImageJ macro responsible for counting and binning chords.
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

	
argument = getArgument(); // the argument may contain flags indicated by "::FLAG::": - leading and trailing colons are required
	//optimize:NNN flag where NNN is the threshold to apply
	//thresholdAC:NNN: flag where NNN is the air content threshold to apply
	//thresholdVF:NNN: flag where NNN is the void frequency threshold to apply
	//analysis:string: flag where string is the analysis method to apply
	// if there are no flags, the script will attempt to load everything from the existing properties file

i_flag = indexOf(argument, "::FLAG::");

s_traverses = "";
i_thresholdAC = NaN;
i_thresholdVF = NaN;
s_analysis = "";

if (i_flag > 0) {
	s_traverses = substring(argument, 0, i_flag);

	// parse the flags:
	a_flags = split(substring(argument, i_flag), ":");
	for (i = 0; i < a_flags.length; i++) {
		if (a_flags[i] == "optimize") {
			// both thresholds will be set to the one supplied:
			i_thresholdAC = parseInt(a_flags[i + 1]);
//			s_analysis = "AC only threshold";
			i_thresholdVF = i_thresholdAC;
		}
		else if (a_flags[i] == "thresholdAC")
			i_thresholdAC = parseInt(a_flags[i + 1]);
		else if (a_flags[i] == "thresholdVF")
			i_thresholdVF = parseInt(a_flags[i + 1]);
		else if (a_flags[i] == "analysis")
			s_analysis = a_flags[i + 1];
	}
}
else
	s_traverses = argument;

if (File.exists(s_traverses)) {
	s_properties = replace(s_traverses, "_traverses", "_bcProps"); //  name of properties file - everything gets dumped here
	a_traverses = split(File.openAsString(s_traverses), "\n");

	List.clear;
	getProps(s_properties);

	// user set parameters
	i_traverses = parseInt(List.get("traverses")); // number of lines to extract from the analysis area selection
	if (isNaN(i_thresholdAC))
		i_thresholdAC = parseInt(List.get("thresholdAC")); // air content threshold
	if (isNaN(i_thresholdVF))
		i_thresholdVF = parseInt(List.get("thresholdVF")); // void frequency threshold
	f_fractionPasteToAgg = parseFloat(List.get("fractionPasteToAgg"));
	f_fractionPaste = parseFloat(List.get("fractionPaste"));
	f_fractionAgg = parseFloat(List.get("fractionAgg"));
	if (s_analysis == "")
		s_analysis = List.get("analysis");

	// determine thresholds to use
	if (s_analysis == "Average threshold") {
		i_avgThreshold = round((i_thresholdAC + i_thresholdVF) / 2);
		i_thresholdAC = i_avgThreshold;
		i_thresholdVF = i_avgThreshold;
	}
	else if (s_analysis == "VF only threshold") {
		i_thresholdAC = i_thresholdVF;
	}
	else if (s_analysis == "AC only threshold") {
		i_thresholdVF = i_thresholdAC;
	}
	
	// initialize calculated values
	i_pixelsTraversed = 0;
	i_chords = 0;
	i_pixelsAir = 0;
	f_pasteToAir = NaN;
	f_airContent = NaN;
	f_spacingFactor = NaN;

	for (i = 0; i < a_traverses.length; i++) {
		a_intensity = split(a_traverses[i], ",");
		i_pixelsTraversed += a_intensity.length;
		// get air content chords and concat to the chords array
		a_chordsTraverse = getChords(a_intensity, i_thresholdAC);
		a_chordsAC = Array.concat(a_chordsTraverse, a_chordsAC);
		// get void frequency chords
		a_chordsTraverse = getChords(a_intensity, i_thresholdVF);
		a_chordsVF = Array.concat(a_chordsTraverse, a_chordsVF);
	}

	// count intercepts, fixed bug in ln106, old version was dividing i_mmAir / i_interceptsAC, kp aug 13 2014
	i_interceptsAC = a_chordsAC.length;
	i_interceptsVF = a_chordsVF.length;
	// bin the chords
	a_chordLengths = newArray(i_interceptsAC);
	a_chordCounts = newArray(i_interceptsAC);
	i_bins = binChords(a_chordsAC, a_chordLengths, a_chordCounts); // binChords returns the number of bins found
	a_chordLengths = Array.trim(a_chordLengths, i_bins); // trim the arrays so there's no empties
	a_chordCounts = Array.trim(a_chordCounts, i_bins);
	// get chord length statistics from the chords found with air content threshold
	Array.getStatistics(a_chordsAC, i_lengthMin, i_lengthMax, f_lengthMean, f_lengthStdDev);
	i_mmTraversed = i_pixelsTraversed * List.get("pixelWidth") / 1000;
	// get the length through air
	i_pixelsAir = pixelsAir(a_chordLengths, a_chordCounts);
	i_mmAir = i_pixelsAir * List.get("pixelWidth") / 1000;
	f_mmLengthMean = i_mmAir / i_interceptsVF;
	f_fractionAir = i_pixelsAir / i_pixelsTraversed;
	// fixed some mistakes in the paste content formulae, had to do with discrepancies between use of volfrac vs. vol% convention, May 23, 2014.
	if (!isNaN(f_fractionPasteToAgg)) if (f_fractionPasteToAgg > 0) f_pasteToAir = (1 - f_fractionAir) * (f_fractionPasteToAgg / (1 + f_fractionPasteToAgg)) / f_fractionAir;
	if (!isNaN(f_fractionPaste)) f_pasteToAir = f_fractionPaste  / f_fractionAir;
	if (!isNaN(f_fractionAgg)) if (f_fractionAgg > 0) f_pasteToAir = (1 - f_fractionAgg - f_fractionAir) / f_fractionAir;
	if (f_pasteToAir > 0) {
		if (f_pasteToAir <= 4.342)
			f_spacingFactor = f_pasteToAir * f_mmLengthMean / 4;
		else
			f_spacingFactor = (3 / 4) * f_mmLengthMean * (1.4 * pow(1 + f_pasteToAir, 1 / 3) - 1);
	}

//		if (File.separator == "\\") s_traverses = replace(List.getList, "\\", "/");
	List.set("pixelsTraversed", i_pixelsTraversed);
	List.set("mmTraversed", i_mmTraversed);
	List.set("interceptsAC", i_interceptsAC);
	List.set("interceptsVF", i_interceptsVF);
	List.set("voidFrequency", i_interceptsVF / i_mmTraversed);
	// save the chords to the list object
	List.set("chordACLengths", delimitArray(a_chordLengths, ","));
	List.set("chordACCounts", delimitArray(a_chordCounts, ","));
	// add the stats to the List object
	List.set("pxLengthMin", i_lengthMin);
	List.set("pxLengthMax", i_lengthMax);
	List.set("pxLengthMean", f_lengthMean);
	List.set("pxLengthStdDev", f_lengthStdDev);
	List.set("specificSurface", 4 / f_mmLengthMean);
	List.set("pixelsAir", i_pixelsAir);
	List.set("lengthMean", f_mmLengthMean);
	List.set("mmAir", i_mmAir);
	List.set("fractionVoid", f_fractionAir);
	List.set("spacingFactor", f_spacingFactor);
	List.set("thresholdAC", i_thresholdAC);
	List.set("thresholdVF", i_thresholdVF);
	List.set("pasteToAir", f_pasteToAir);
	
	// return the List object as a string
	return List.getList;
}
else
	return "NA" ;


exit;

function getChords(
	a_intensity,
	i_threshold) {

	var a_chordsTemp = newArray(a_intensity.length);
	i_lengthChord = 0;
	i_chords = 0;
	for (i = 0; i < a_intensity.length; i++) {
		if (parseInt(a_intensity[i]) >= i_threshold) {
			// on a chord
			i_lengthChord++;
		}

		else {
			// not on a chord
			// see if just exited a chord
			if (i_lengthChord > 0) {
				// exited a chord
				a_chordsTemp[i_chords] = i_lengthChord;
				i_chords++;
				i_lengthChord = 0;
			}

		}
	}
	return Array.trim(a_chordsTemp, i_chords);
} // end function getChords

function binChords(
	a_chordsToBin,
	a_binLengths,
	a_binCounts) {

	Array.sort(a_chordsToBin);
	i_bins = 0;
	i_countsCurrent = 1;
	i_lengthPrevious = a_chordsToBin[0];
	a_binLengths[0] = a_chordsToBin[0];
	for(i = 0; i < a_chordsToBin.length; i++) {
		if (i_lengthPrevious != a_chordsToBin[i]) {
			a_binCounts[i_bins] = i_countsCurrent;
			i_countsCurrent = 1;
			i_bins++;
			a_binLengths[i_bins] = a_chordsToBin[i];
			i_lengthPrevious = a_chordsToBin[i];
		}

		else {
			i_countsCurrent++;
		}
	}
	return i_bins;
} // end function binChords

function pixelsAir(
	a_binLengths,
	a_binCounts) {

	i_pixelsAir = 0;
	for (i = 0; i < a_binLengths.length; i++)
		i_pixelsAir += a_binLengths[i] * a_binCounts[i];

	return i_pixelsAir;
}

// reads the properties file
function getProps(s_properties) {
	List.setList(File.openAsString(s_properties));
} // end function getProps

function delimitArray(a, delimitter) {
	s = "";
	for (i = 0; i < a.length - 1; i++)
		s = s + a[i] + delimitter;

	s = s + a[a.length - 1];

	return s;
}
