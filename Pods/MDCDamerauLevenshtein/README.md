# MDCDamerauLevenshtein

[![Build Status](https://travis-ci.org/modocache/MDCDamerauLevenshtein.svg?branch=master)](https://travis-ci.org/modocache/MDCDamerauLevenshtein)

Categories to calculate the edit distance between `NSString` objects.

```objc
#import <MDCDamerauLevenshtein/MDCDamerauLevenshtein.h>

[@"Central Park" mdc_levenshteinDistanceTo:@"Centarl Prak"];         // => 4
[@"Central Park" mdc_damerauLevenshteinDistanceTo:@"Centarl Prak"];  // => 2
```

MDCDamerauLevenshtein includes two algorithms for calculating
the edit distance between NSString objects:

1. Levenshtein distance calculates the number of insertions,
  deletions, and substitions necessary in order to convert one
  string into the other.
2. Damerau-Levenshtein improves upon Levenshtein to include the
  transposition of two adjacent characters. Damerau states that
  some combination of the four operations make up for 80% of all
  human spelling errors.

Potential applications for this library:

- Don't just use `-[NSString compare:options:]` to filter search results,
 display terms with small edit distances.
- ...and many more!

## Benchmarking Against Other Implmentations

The benchmarking app is included in this repository. It consists of two benchmarks:

1. **Normal:** Finding the Levenshtein distance between "sitting" and "kitten"
2. **Large:** Finding the Levenshtein distance between two paragraphs of text (409 and 728 characters, respectively)

<table>
  <tr>
    <th>Library</th>
    <th>Avg. Time (Normal)</th>
    <th>Avg. Time (Large)</th>
  </tr>
  <tr>
    <td>MDCDamerauLevenshtein</td>
    <td>14,218 nanoseconds</td>
    <td>0.0792383 seconds</td>
  </tr>
  <tr>
    <td>NSString+LevenshteinDistance</td>
    <td>17,812 nanoseconds (25% slower)</td>
    <td>0.0949104 seconds (20% slower)</td>
  </tr>
</table>

> [koyachi/NSString-LevenshteinDistance](https://github.com/koyachi/NSString-LevenshteinDistance)
  only computes Levenshtein distance, not Damerau-Levenshtein, so only Levenshtein benchmarks are included here.
  The project does not include unit tests, but when benchmarked it produced correct distances.

