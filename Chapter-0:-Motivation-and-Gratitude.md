AMMonitor: An R Package for Remote Biodiversity Monitoring
================

  - [Disclaimer](#disclaimer)
  - [Background](#background)
  - [Gratitude](#gratitude)
  - [References](#references)

# Disclaimer

This draft manuscript is distributed solely for purposes of scientific
peer review. Its content is deliberative and predecisional, so it must
not be disclosed or released by reviewers. Because the manuscript has
not yet been approved for publication by the U.S. Geological Survey
(USGS), it does not represent any official USGS finding or policy.

# Background

Amid climate change and rapidly shifting land uses, effective methods
for monitoring natural resources are critical to support
scientifically-informed resource management decisions \[1–5\]. The
practice of using Autonomous Monitoring Units (AMUs) to monitor wildlife
species has grown immensely in the past decade, with monitoring projects
across species from birds, to bats, amphibians, insects, terrestrial
mammals, and marine mammals \[6,7\].

AMUs have many benefits. Primarily, they can be deployed for long
periods of time to collect massive amounts of data, such as audio
recordings and photos. Having a record of audio and photo data allows
researchers to carefully verify and analyze species identifications *a
posteriori* \[8\].

However, automated methods have several limitations. First, individual
AMUs can be expensive, running over $800 USD for commercial devices
\[9\], although cost-effective models are becoming more common \[10\].
Second, data are typically stored on AMUs until researchers can retrieve
it, causing time lapses between data collection, analysis, and results.
Such delays hamper the ability to efficiently address pressing
ecological challenges and track progress toward management objectives.
Third, the data management requirements of an AMU research effort are
often immense. A monitoring program is a collection of people,
equipment, monitoring locations, location characteristics, research
objectives, and data files, with multiple moving parts to manage.
Without a comprehensive framework for efficiently moving from raw data
collection to results and analysis, monitoring programs are limited in
their capacity to characterize ecological processes and inform
management decisions \[12–18\].

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
energy projects are added to the landscape. Thus, AMMonitor’s primary
function is to enable the practice of **a**daptive **m**anagement via a
novel and flexible integrated system.

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

# References

<div id="refs" class="references">

<div id="ref-Holling1978">

1\. Holling CS, United Nations Environment Programme. Adaptive
environmental assessment and management. Laxenburg, Austria; Chichester,
New York: International Institute for Applied Systems Analysis; Wiley;
1978. pp. xviii, 377p. 

</div>

<div id="ref-Walters1986">

2\. Walters C. Adaptive management of renewable resources. New York:
Macmillan; 1986. p. 374 p. 

</div>

<div id="ref-Lee1993">

3\. Lee K. Compass and gyroscope: Integrating science and politics for
the environment. Washington DC: Island Press; 1993. p. 255 p. 

</div>

<div id="ref-Pollock2002">

4\. Pollock KH, Nichols JD, Simons TR, Farnsworth GL, Bailey LL, Sauer
JR. Large scale wildlife monitoring studies: Statistical methods for
design and analysis. Environmetrics. 2002;13: 105–119. 

</div>

<div id="ref-Allen2015">

5\. Allen CR, Garmestani AS, editors. Adaptive management of
social-ecological systems \[Internet\]. Springer Science Mathplus
Business Media; 2015.
doi:[10.1007/978-94-017-9682-8](https://doi.org/10.1007/978-94-017-9682-8)

</div>

<div id="ref-August2015">

6\. August T, Harvey M, Lightfoot P, Kilbey D, Papadopoulos T, Jepson P.
Emerging technologies for biological recording. Biological Journal of
the Linnean Society. 2015;115: 731–749. 

</div>

<div id="ref-Burton2015">

7\. Burton AC, Neilson E, Moreira D, Ladle A, Steenweg R, Fisher JT, et
al. Wildlife camera trapping: A review and recommendations for linking
surveys to ecological processes. Journal of Applied Ecology. 2015;52:
675–685. 

</div>

<div id="ref-Hobson2002">

8\. Hobson KA, Rempel RS, Greenwood H, Turnbull B, Van Wilgenburg SL.
Acoustic surveys of birds using electronic recordings: New potential
from an omnidirectional microphone system. Wildlife Society Bulletin.
2002;30: 709–720. 

</div>

<div id="ref-WildlifeAcoustics2019">

9\. Song meter sm4 \[acoustic recording hardware\] \[Internet\].
Wildlife Acoustics; 2019. Available:
<https://www.wildlifeacoustics.com/products/song-meter-sm4>

</div>

<div id="ref-Whytock2017">

10\. Whytock RC, Christie J. Solo: An open source, customizable and
inexpensive audio recorder for bioacoustic research. Methods in Ecology
and Evolution. 2017;8: 308–312. 

</div>

<div id="ref-Hill2018">

11\. Hill AP, Prince P, Piña Covarrubias E, Doncaster CP, Snaddon JL,
Rogers A. AudioMoth: Evaluation of a smart open acoustic device for
monitoring biodiversity and the environment. Methods in Ecology and
Evolution. 2018;9: 1199–1211. 

</div>

<div id="ref-Gregory2006">

12\. Gregory R, Ohlson D, Arvai J. Deconstructing adaptive management:
Criteria for applications to environmental management. Ecological
Applications. 2006;16: 2411–2425. 

</div>

<div id="ref-Rehme2011">

13\. Rehme SE, Powell LA, Allen CR. Multimodel inference and adaptive
management. Journal of Environmental Management. 2011;92: 1360–1364. 

</div>

<div id="ref-Fontaine2011">

14\. Fontaine JJ. Improving our legacy: Incorporation of adaptive
management into state wildlife action plans. Journal of Environmental
Management. 2011;92: 1403–1408. 

</div>

<div id="ref-Greig2013">

15\. Greig LA, Marmorek DR, Murray C, Robinson DCE. Insight into
enabling adaptive management. Ecology and Society. 2013;18. 

</div>

<div id="ref-Rist2013">

16\. Rist L, Felton A, Samuelsson L, Sandstrom C, Rosvall O. A new
paradigm for adaptive management. Ecology and Society. 2013;18. 

</div>

<div id="ref-Fischman2016">

17\. Fischman RL, Ruhl JB. Judging adaptive management practices of us
agencies. Conservation Biology. 2016;30: 268–275. 

</div>

<div id="ref-Williams2016">

18\. Williams BK, Brown ED. Technical challenges in the application of
adaptive management. Biological Conservation. 2016;195: 255–263. 

</div>

</div>
