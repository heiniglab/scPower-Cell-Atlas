# Enabling cell atlas guided optimal experimental design

## Table of contents
- Project Overview
  - [Abstract](#abstract)
  - [Project Purpose](#project-purpose)
  - [Presented at](#presented-at)
- [Abstract](#abstract)

## Abstract
We have previously developed [scPower](https://www.nature.com/articles/s41467-021-26779-7) - a statistical framework that allows users to optimize the power of their experimental design of multi-sample single-cell transcriptomics with a user-friendly interface. However, it requires cell type-specific prior information. Previously this information was available only for selected cell types and tissues. Now with the increasing availability of reference cell atlases available, we can scale our framework to allow experimental design an all known cells of an organism. <br>
We systematically apply scPower wrapped into a data processing and data management infrastructure to obtain the required prior information on cell type-specific gene expression distributions. Based on these systematic priors, a unified experimental design online resource will be established. It will enable researchers to design the most powerful experiments for the identification of differential expression or eQTL in their respective application areas. In future work, this model will further be extended to allow for the optimal design of allele-specific expression and perturbation experiments such as CROP-seq and Perturb-seq.

## Project Purpose
To develop an online resource for optimal experimental design and power analysis of cell type-specific multisample comparisons and CRISPR screening single-cell transcriptomics experiments.

## Presented at:
``08 December 2022`` Helmholtz Munich - Kim-Hellmuth/Heinig joint Group Meetin Day <br>
``18 April 2023`` &emsp;&nbsp; RECOMB - 27th Annual International Conference on Research in Computational Molecular Biology

## Resources
contained in the project and their details can be found [here](https://github.com/Cem-Gulec/Helmholtz-Workspace/blob/main/Data-Descriptor/Cell-Level/scPower-wrapper/results/README.md). <br>
Documentation can be found [here](https://helmholtz-workspace.readthedocs.io/en/latest/)

## 🗂 Repository Map  
<pre style="font-family:Menlo,'DejaVu Sans Mono',consolas,'Courier New',monospace">┏━━ 📰 Data-Descriptor
┃   ┣━━ 🧫 Cell-Level: scPower wrapper
┃   ┃   ┣━━ code: main codes (.R and .Rmd) are contained here
┃   ┃   ┗━━ results: dataset-specific ones (descriptive parameters, estimations, errors, dispersion function estimation, gamma linear fits, gene ranks, power results) and
┃   ┃                general results either across all datasets or some general assumptions for a group of them are contained here.
┃   ┃
┃   ┗━━ 🧬 Collection-Level: cellxgene scrapper with both puppeteer, Go, and sfaira connection point
┃
┣━━ 🔬 Experimentation: consists of useful scripts I use during the development of the project, also for plotting things
┃
┣━━ 📦 Web-Server
┃   ┣━━ Backend: services created with Go and database scripts
┃   ┃
┃   ┗━━ Frontend: web server created with Vue.js
┃
┗━━ 📄 Documentation: presentations done related to the project
</pre>

## Workflow 
Here, I will add how the pipeline is built on top of scPower. Also, any parts extended on scPower will be demonstrated here...

## Getting started
In this section, we will show you how to customize the necessary parts for your needs.

## Installation
Here, installation steps will be explained...

## [Steps](https://github.com/scverse/cookiecutter-scverse/blob/main/README.md#set-up-online-services) that could be included in the future:
-   pre-commit checks for code style and consistency
-   automated testing with testthat
-   coverage tests with covr
-   continuous integration using GitHub actions.
-   documentation hosted by readthedocs
-   tutorials markdown notebooks
-   bump2version for managing releases
-   creating project with cruft like tool which enables automatic updates

✔   issue templates for better bug reports and feature requests <br>

Acknowledgements to [cookiecutter-scverse](https://github.com/scverse/cookiecutter-scverse) for this.
