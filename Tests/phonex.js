/**
 * Talisman phonetics/phonex
 * ==========================
 *
 * Implementation of the "Phonex" algorithm.
 *
 * [Reference]:
 * http://homepages.cs.ncl.ac.uk/brian.randell/Genealogy/NameMatching.pdf
 *
 * [Article]:
 * Lait, A. J. and B. Randell. "An Assessment of Name Matching Algorithms".
 */
// import deburr from "lodash/deburr";

/**
 * Constants.
 */
const INITIALS = [ [ "AEIOUY", "A" ], [ "BP", "B" ], [ "VF", "F" ], [ "KQC", "C" ], [ "JG", "G" ], [ "ZS", "S" ] ];

INITIALS.forEach(rule => (rule[0] = new Set(rule[0])));

const B_SET = new Set("BPFV"), C_SET = new Set("CSKGJQXZ"), VOWELS_SET = new Set("AEIOUY");

/**
 * Function taking a single name and computing its Phonex code.
 *
 * @param  {string}  name - The name to process.
 * @return {string}       - The Phonex code.
 *
 * @throws {Error} The function expects the name to be a string.
 */
function phonex(name) {
    if (typeof name !== "string")
        throw Error("talisman/phonetics/phonex: the given name is not a string.");

    if (!name)
        return "";

    // Deburring the string & dropping any non-alphabetical character
    // name = deburr( name )
    name = name.toUpperCase().replace(/[^A-Z]/g, "");

    // Removing trailing S
    name = name.replace(/S+$/, "");

    // Substitution of some initials
    const firstTwoLetter = name.slice(0, 2), rest = name.slice(2);

    if (firstTwoLetter === "KN")
        name = "N" + rest;
    else if (firstTwoLetter === "PH")
        name = "F" + rest;
    else if (firstTwoLetter === "WR")
        name = "R" + rest;

    // Ignoring first H if present
    if (name[0] === "H")
        name = name.slice(1);

    // Encoding first character
    for (let i = 0, l = INITIALS.length; i < l; i++) {
        const [letters, replacement] = INITIALS[i];

        if (letters.has(name[0])) {
            name = replacement + name.slice(1);
            break;
        }
    }

    let code = name[0], last = code;

    for (let i = 1, l = name.length; i < l; i++) {
        const letter = name[i], nextLetter = name[i + 1];

        let encoding = "0";

        if (B_SET.has(letter)) {
            encoding = "1";
        } else if (C_SET.has(letter)) {
            encoding = "2";
        } else if (letter === "D" || letter === "T") {
            if (nextLetter !== "C")
                encoding = "3";
        } else if (letter === "L") {
            if (VOWELS_SET.has(nextLetter) || i + 1 === l)
                encoding = "4";
        } else if (letter === "M" || letter === "N") {
            if (nextLetter === "D" || nextLetter === "G")
                name = name.slice(0, i + 1) + letter + name.slice(i + 2);
            encoding = "5";
        } else if (letter === "R") {
            if (VOWELS_SET.has(nextLetter) || i + 1 === l)
                encoding = "6";
        }

        if (encoding !== last && encoding !== "0")
            code += encoding;

        last = code.slice(-1);
    }

    return code;
}
