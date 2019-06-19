AMMonitor: An R Package for Remote Biodiversity Monitoring
================

  - [Disclaimer](#disclaimer)
  - [Background](#background)
  - [Gratitude](#gratitude)
  - [Bibliography](#bibliography)

# Disclaimer

This draft manuscript is distributed solely for purposes of scientific
peer review. Its content is deliberative and predecisional, so it must
not be disclosed or released by reviewers. Because the manuscript has
not yet been approved for publication by the U.S. Geological Survey
(USGS), it does not represent any official USGS finding or policy.

# Background

**AMMonitor** is an open source R package dedicated to collecting,
storing, and analyzing AMU information in a way that 1) is
cost-effective, 2) can efficiently process and store information, 3) can
mitigate false positive and false negative detections, and 4) can take
advantage of the vast and growing community of R analytics. We created
AMMonitor for the U.S. Bureau of Land Management to monitor high
priority wildlife across the southern California Solar Energy Zone
(SEZ), including the Couch’s spadefoot toad (*Scaphiopus couchii*), kit
fox (*Vuples macrotis*), coyote (*Canis latrans*), and a variety of bird
species, such as the Verdin (*Auriparus flaviceps*), Black-tailed
Gnatcatcher (*Polioptila melanura*), and Eurasian Collared-dove
(*Streptopelia decaocto*). The agency has established management
objectives (benchmarks) to ensure the persistence of sensitive species
and minimize the spread of invasive species across the SEZ as solar
energy projects are added to the landscape.

In developing **AMMonitor**, our primary goal was to create a system for
handling and processing massive amounts of data to allow BLM to quickly
ascertain species distribution patterns (e.g., an occupancy analysis) in
relation to their management objectives. The **AMMonitor** package
builds upon the software **monitoR** (Katz, Hafner, and Donovan, 2016),
an R package developed in T. Donovan’s lab that uses spectrogram
cross-correlation and binary point matching algorithms to automatically
search audio files for target sounds. The **AMMonitor** package places
the monitoring data into an adaptive management framework (Williams,
2011), and was developed with a prototype of 20 AMU units (smartphones)
by C. Balantic and T. Donovan (Balantic and Donovan, 2019a; Balantic and
Donovan, 2019b; Balantic and Donovan, 2019c). Since then, we have added
the capacity to use the smartphone’s camera by enabling timed
photographs as well as motion-triggered photographs, allowing the
smartphones to act as “cam-trackers.”

This guide has been written to illustrate the **AMMonitor** approach as
it currently stands. We welcome collaborators who may be interested in
improving or building on our approach.

# Gratitude

We thank Mark Massar and the BLM for ….Jon Katz….Jim Hines….John Sauer

# Bibliography

    <p><a id='bib-BalanticOccupancy'></a><a href="#cite-BalanticOccupancy">[1]</a><cite>
    C. Balantic and T. Donovan.
    &ldquo;Dynamic wildlife occupancy models using automated acoustic monitoring data&rdquo;.
    In: <em>Ecological Applications</em> 29.3 (2019), p. e01854.</cite></p>
    
    <p><a id='bib-BalanticStatistical'></a><a href="#cite-BalanticStatistical">[2]</a><cite>
    C. Balantic and T. Donovan.
    &ldquo;Statistical learning mitigation of false positive detections in automated acoustic wildlife monitoring&rdquo;.
    In: <em>2019</em> (2019).</cite></p>
    
    <p><a id='bib-BalanticTemporal'></a><a href="#cite-BalanticTemporal">[3]</a><cite>
    C. Balantic and T. Donovan.
    &ldquo;Temporally-adaptive acoustic sampling to maximize detection across a suite of focal wildlife species&rdquo;.
    In: <em>In review</em> (2019).</cite></p>
    
    <p><a id='bib-Katz2016'></a><a href="#cite-Katz2016">[4]</a><cite>
    J. Katz, S. Hafner and T. Donovan.
    &ldquo;Tools for automated acoustic monitoring within the R package monitoR&rdquo;.
    In: <em>Bioacoustics</em> 12 (2016), pp. 50-67.</cite></p>
    
    <p><a id='bib-Williams2011'></a><a href="#cite-Williams2011">[5]</a><cite>
    B. K. Williams.
    &ldquo;Adaptive management of natural resources-framework and issues&rdquo;.
    In: <em>Journal of Environmental Management</em> 92.5 (2011), pp. 1346-1353.</cite></p>
