s_directory = getDirectory("Choose a Directory Containing Photoshop-Analyzed Images");
a_files = getFileList(s_directory);

for (i = 0; i < a_files.length; i++) {
	s_file = a_files[i];

	if (indexOf(s_file, "_props.csv") > 0) {
		s_rootFN = replace(s_file, "_props.csv", "");
		// make sure there's a text tif:
		s_txtTif = s_directory + s_rootFN + "_comp.txt";
		s_traverses = s_directory + s_rootFN + "_traverses.txt";
		if (File.exists(s_txtTif)) {
			// open the PS txt tif image and replace tabs with commas
			f_traverses = File.open(s_traverses);
			print(f_traverses, replace(File.openAsString(s_txtTif), "\t", ","));
			File.close(f_traverses);
			s_PSProps = File.openAsString(s_directory + s_file);
			
			// split by lines:
			a_lines = split(s_PSProps, "\n");
			// iterate through the lines, split on commas and locate the modes:
			modeBlack = 0 / 0;
			modeWhite = 0 / 0;
			pixelWidth = 0 / 0;
			traverses = 0 / 0;
			fractionPasteToAgg = 0 / 0;
			fractionPaste = 0 / 0;
			fractionAgg = 0 / 0;

			j = 0;
			while (j < a_lines.length && (isNaN(modeBlack) || isNaN(modeWhite) || isNaN(pixelWidth) || isNaN(traverses) || (isNaN(fractionPasteToAgg) && isNaN(fractionPaste) && isNaN(fractionAgg)))) {
				a_line = split(a_lines[j], ",");
				if (a_line.length > 1) {
					if (a_line[0] == "intensityBlackMax") modeBlack = a_line[2];

					if (a_line[0] == "intensityWhiteMax") modeWhite = a_line[2];

					if (a_line[0] == "resolution") pixelWidth = 25400 / parseInt(a_line[1]);

					if (a_line[0] == "traverses") traverses = a_line[1];

					if (a_line[0] == "pasteToAgg") fractionPasteToAgg = parseFloat(a_line[1]) / 100;

					if (a_line[0] == "pasteVolume") fractionPaste = parseFloat(a_line[1]) / 100;

					if (a_line[0] == "aggVolume") fractionAgg = parseFloat(a_line[1]) / 100;
				}
				j++;
			}
		}

		List.set("nameFileOriginal", s_rootFN + ".tif");
		List.set("modeWhite", modeWhite);
		List.set("modeBlack", modeBlack);
		List.set("pixelWidth", pixelWidth);
		List.set("traverses", traverses);
		List.set("fractionPasteToAgg", fractionPasteToAgg);
		List.set("fractionPaste", fractionPaste);
		List.set("fractionAgg", fractionAgg);
		f = File.open(s_directory + s_rootFN + "_bcProps.txt");
		//old version wrote _bcprops.txt instead of bcProps.txt, kp aug 14 2014, fixed here.
		print(f, List.getList);
		File.close(f);
	}
}

showMessage ("All Done!");
