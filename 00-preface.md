AMMonitor: Remote Monitoring of Biodiversity in an Adaptive Framework
================

  - [Background](#background)
  - [Gratitude](#gratitude)
  - [Chapter References](#chapter-references)

<!--html_preserve-->

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAACJCAIAAABb6cuEAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA2ZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo2RjAzMzM3QjYxOUVFOTExQUI4NkI2Q0I0Mjg3RUM0NyIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDowOUFDRjZDRDlFODUxMUU5QjdGNzlCN0NEMUNBQUVBMyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDowOUFDRjZDQzlFODUxMUU5QjdGNzlCN0NEMUNBQUVBMyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M1LjEgV2luZG93cyI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZGMDMzMzdCNjE5RUU5MTFBQjg2QjZDQjQyODdFQzQ3IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjZGMDMzMzdCNjE5RUU5MTFBQjg2QjZDQjQyODdFQzQ3Ii8+IDwvcmRmOkRlc2NyaXB0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" alt="logo" style="position:absolute; top:0; right:0; padding:5px;"/><!--/html_preserve-->

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
\[9\], although cost-effective models are becoming more common
\[10,11\]. Second, data is typically stored on AMUs until researchers
can retrieve it, causing time lapses between data collection, analysis,
and results. Such delays hamper the ability to efficiently address
pressing ecological challenges and track progress toward management
objectives. Third, the data management requirements of an AMU research
effort are often immense. A monitoring program is a collection of
people, equipment, monitoring locations, location characteristics,
research objectives, and data files, with multiple moving parts to
manage. Without a comprehensive framework for efficiently moving from
raw data collection to results and analysis, monitoring programs are
limited in their capacity to characterize ecological processes and
inform management decisions \[12–18\].

**AMMonitor** is an open source R package dedicated to collecting,
storing, and analyzing AMU information in a way that 1) is
cost-effective, 2) can efficiently process and store information, and 3)
can take advantage of the vast and growing community of R analytics. We
created **AMMonitor** for the Bureau of Land Management to monitor high
priority wildlife across the southern California Solar Energy Zone
(SEZ), including the Couch’s Spadefoot (*Scaphiopus couchii*), kit fox
(*Vuples macrotis*), coyote (*Canis latrans*), and a variety of bird
species, such as the Verdin (*Auriparus flaviceps*), Black-tailed
Gnatcatcher (*Polioptila melanura*), and Eurasian Collared-Dove
(*Streptopelia decaocto*). The agency has established management
objectives (benchmarks) to ensure the persistence of sensitive species
and minimize the spread of invasive species across the SEZ as solar
energy projects are added to the landscape. In developing **AMMonitor**,
our primary goal was to create a system for handling and processing
massive amounts of data to allow BLM to quickly ascertain species
distribution patterns (e.g., an occupancy analysis) in relation to their
management objectives.

In broad terms, the **AMMonitor** approach starts with ecological
hypotheses or natural resource management objectives (Figure 0.1;
boxed). Data are collected with Autonomous Monitoring Units (AMUs) to
test hypotheses or to evaluate the state of a resource with respect to a
management objective. Acoustic recordings and photos are collected and
delivered to the cloud. Raw and processed data are stored in a SQLite
database. The data can be analyzed with a wide variety of analytical
methods, often models of abundance or occupancy pattern. These analyses
can be stored, and resulting outputs can be compared with research and
monitoring objectives to track progress toward management goals. The
final results are assessed with respect to hypotheses or objectives.
Thus, the **AMMonitor** package places the monitoring data into an
**a**daptive **m**anagement framework
\[19\].

<kbd>

<img src="Chap0_Figs/fig1.png" width="100%" style="display: block; margin: auto;" />
</kbd>

> *Figure 0.1. The general AMMonitor framework begins with basic
> research hypotheses or applied resource management objectives
> (boxed).*

The **AMMonitor** approach was developed with a prototype of 20
smartphone-based AMUs \[20–22\]. Since then, we have added the capacity
to use the smartphone’s camera by enabling timed photographs as well as
motion-triggered photographs, allowing the smartphones to act as camera
traps. However, the **AMMonitor** approach does not require the use of
smartphones. Its flexibility allows the analyis of data collected by
other autonomous devices, and further permits the storage of results
from other analytical systems for additional processing in R.

This guide provides step-by-step instructions for using **AMMonitor** in
its current form for monitoring programs that rely on remotely-captured
data for use in adaptive management. We welcome collaborators who may be
interested in improving or building on our approach.

# Gratitude

We thank Mark Massar and the Bureau of Land Management for essential
field support and guidance, Jon Katz and Jim Hines for programming
assistance, and John Sauer for critical review of the software and
documentation.

# Chapter References

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

8\. Hobson KA, Rempel RS, Greenwood H, Turnbull B, Van Wilgenburg S.
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
paradigm for adaptive management. Ecology and Society. 2013;18: 63.
Available: <http://dx.doi.org/10.5751/ES-06183-180463>

</div>

<div id="ref-Fischman2016">

17\. Fischman RL, Ruhl JB. Judging adaptive management practices of us
agencies. Conservation Biology. 2016;30: 268–275. 

</div>

<div id="ref-Williams2016">

18\. Williams BK, Brown ED. Technical challenges in the application of
adaptive management. Biological Conservation. 2016;195: 255–263. 

</div>

<div id="ref-Williams2011">

19\. Williams BK. Adaptive management of natural resources-framework and
issues. Journal of Environmental Management. 2011;92: 1346–1353. 

</div>

<div id="ref-BalanticStatistical">

20\. Balantic CM, Donovan TM. Statistical learning mitigation of false
positives from template-detected data in automated acoustic wildlife
monitoring. Bioacoustics. Taylor & Francis; 2019;0: 1–26.
doi:[10.1080/09524622.2019.1605309](https://doi.org/10.1080/09524622.2019.1605309)

</div>

<div id="ref-BalanticOccupancy">

21\. Balantic C, Donovan T. Dynamic wildlife occupancy models using
automated acoustic monitoring data. Ecological Applications. 2019;29:
e01854. doi:[10.1002/eap.1854](https://doi.org/10.1002/eap.1854)

</div>

<div id="ref-BalanticTemporal">

22\. Balantic C, Donovan T. Temporally-adaptive acoustic sampling to
maximize detection across a suite of focal wildlife species. Ecology and
Evolution. 

</div>

</div>
