.. _sdr:

****************************
SDR: Sediment Delivery Ratio
****************************

Summary
=======

The objective of the InVEST Sediment Delivery Ratio (SDR) model is to map overland sediment generation and delivery to the stream. In the context of global change, such information can be used to study the service of sediment retention in a catchment. This is of particular interest for reservoir management and instream water quality, both of which may be economically valued.


Introduction
============

Erosion and overland sediment retention are natural processes that govern the sediment concentration in streams. Sediment dynamics at the catchment scale are mainly determined by climate (in particular rain intensity), soil properties, topography, and vegetation; and anthropogenic factors such as agricultural activities or dam construction and operation. Main sediment sources include overland erosion (soil particles detached and transported by rain and overland flow), gullies (channels that concentrate flow), bank erosion, and mass erosion (or landslides; see Merrit 2003 for a review). Sinks include on-slope, floodplain or instream deposition, and reservoir retention, as summarized in Figure 1. Conversion of land use and changes in land management practices may dramatically modify the amount of sediment running off a catchment. The magnitude of this effect is primarily governed by: i) the main sediment sources (land use change will have a smaller effect in catchments where sediments are not primarily coming from overland flow); and ii) the spatial distribution of sediment sources and sinks (for example, land use change will have a smaller effect if the sediment sources are buffered by vegetation).

Increases in sediment yield are observed in many places in the world, dramatically affecting water quality and reservoir management (UNESCO 2009). The sediment retention service provided by natural landscapes is of great interest to water managers. Understanding where the sediments are produced and delivered allow managers to design improved strategies for reducing sediment loads. Changes in sediment load can have impacts on downstream irrigation, water treatment, recreation and reservoir performance.

Outputs from the sediment model include the sediment load delivered to the stream at an annual time scale, as well as the amount of sediment eroded in the catchment and retained by vegetation and topographic features. Note that SDR only creates biophysical results. For valuation of the sediment retention service, appropriate valuation approaches will be highly dependent on the particular application and context, and need to be implemented independently of InVEST.

|
|

.. figure:: ./sdr/sediment_budget.png

    General catchment sediment budget. The relative size of the arrows changes depending on the environment. The InVEST model focuses on the overland sources and sinks, and does not include the others.


The Model
=========

Sediment Delivery
-----------------

The sediment delivery module is a spatially-explicit model working at the spatial resolution of the input digital elevation model (DEM) raster. For each pixel, the model first computes the amount of annual soil loss from that pixel, then computes the sediment delivery ratio (SDR), which is the proportion of soil loss actually reaching the stream. Once sediment reaches the stream, we assume that it ends up at the catchment outlet, thus no in-stream processes are modeled. This approach was proposed by Borselli et al. (2008) and has received increasing interest in recent years (Cavalli et al., 2013; López-vicente et al., 2013; Sougnez et al., 2011). See the User Guide section **Differences between the InVEST SDR model and the original approach developed by Borselli et al. (2008)** for further discussion.


Annual Soil Loss
^^^^^^^^^^^^^^^^

The amount of annual soil loss on pixel :math:`i`, :math:`usle_i` (units: :math:`tons\cdot ha^{-1} yr^{-1}`), is given by the revised universal soil loss equation (RUSLE1):

.. math:: usle_i=R_i\cdot K_i\cdot LS_i\cdot C_i\cdot P_i,
   :label: usle

where

 * :math:`R_i` is rainfall erosivity (units: :math:`MJ\cdot mm (ha\cdot hr)^{-1})`,

 * :math:`K_i` is soil erodibility (units: :math:`ton\cdot ha\cdot hr (MJ\cdot ha\cdot mm)^{-1}`),

 * :math:`LS_i` is a slope length-gradient factor (unitless)

 * :math:`C_i` is a crop-management factor (unitless)

 * and :math:`P_i` is a support practice factor (Renard et al., 1997). (cf. also in (Bhattarai and Dutta, 2006)). (unitless)

The :math:`LS_i` factor is given from the method developed by Desmet and Govers (1996) for a two-dimensional surface:

.. math:: LS_i=S_i \frac{(A_{i-in}+D^2)^{m+1}-A_{i-in}^{m+1}}{D^{m+2}\cdot x_i^m\cdot (22.13)^m}
    :label: ls

where

 * :math:`S_i` is the slope factor for grid cell :math:`i` calculated as a function of slope radians :math:`\theta`

  - :math:`S=10.8\cdot\sin(\theta)+0.03` where :math:`\theta < 9\%`
  - :math:`S=16.8\cdot\sin(\theta)-0.50`, where :math:`\theta \geq 9\%`

 * :math:`A_{i-in}` is the contributing area (:math:`m^2`) at the inlet of a grid cell which is computed from the Multiple-Flow Direction method

 * :math:`D` is the grid cell linear dimension (:math:`m`)

 * :math:`x_i` is the mean of aspect weighted by proportional outflow from grid cell :math:`i` determined by a Multiple-Flow Direction algorithm.  It is calculated by :math:`\sum_{d\in{\{0,7\}}} x_d\cdot P_i(d)` where :math:`x_d = |\sin \alpha(d)| + |\cos \alpha(d)|` where :math:`\alpha(d)` is the radian angle for direction :math:`d` and :math:`P_i(d)` is the proportion of total outflow at cell :math:`i` in direction :math:`d`.

 * :math:`m` is the RUSLE length exponent factor.


To avoid overestimation of the LS factor in heterogeneous landscapes, long slope lengths are capped to a maximum value of 122m that is adjustable as a user parameter (Desmet and Govers, 1996; Renard et al., 1997).

The value of :math:`m`, the length exponent of the LS factor, is based on the classical USLE, as discussed in (Oliveira et al., 2013):

 * :math:`m = 0.2` for slope <= 1%:
 * :math:`m = 0.3` for 1% < slope <= 3.5%
 * :math:`m = 0.4` for 3.5% < slope <= 5%
 * :math:`m = 0.5` for 5% < slope <= 9%
 * :math:`m = \beta / (1 + \beta)` where :math:`\beta=\sin\theta / 0.0986 / (3\sin\theta^{0.8} + 0.56)` for slope >= 9%


Sediment Delivery Ratio
^^^^^^^^^^^^^^^^^^^^^^^

**Step 1.** Based on the work by Borselli et al. (2008), the model first computes the connectivity index (:math:`IC`) for each pixel. The connectivity index describes the hydrological linkage between sources of sediment (from the landscape) and sinks (like streams.) Higher values of :math:`IC` indicate that source erosion is more likely to make it to a sink (i.e. is more connected), which happens, for example, when there is sparse vegetation or higher slope. Lower values of :math:`IC` (i.e. lower connectivity) are associated with more vegetated areas and lower slopes.

:math:`IC` is a function of both the area upslope of each pixel (:math:`D_{up}`) and the flow path between the pixel and the nearest stream (:math:`D_{dn}`). If the upslope area is large, has lower slope, and good vegetative cover (so a low USLE C factor), :math:`D_{up}` will be low, indicating a lower potential for sediment to make it to the stream. Similarly, if the downslope path between the pixel and the stream is long, has lower slope and good vegetative cover, :math:`D_{dn}` will be low.

:math:`IC` is calculated as follows:

.. math:: IC=\log_{10} \left(\frac{D_{up}}{D_{dn}}\right)
    :label: ic

.. figure:: ./sdr/connectivity_diagram.png

Figure 2. Conceptual approach used in the model. The sediment delivery ratio (SDR) for each pixel is a function of the upslope area and downslope flow path (Equations 3, 4, 5).

:math:`D_{up}` is the upslope component defined as:

.. math:: D_{up}=\bar{C}\bar{S}\sqrt{A}
    :label: d_up

where :math:`\bar{C}` is the average :math:`C` factor of the upslope contributing area, :math:`S` is the average slope gradient of the upslope contributing area (:math:`m/m`) and :math:`A` is the upslope contributing area (:math:`m^2`). The upslope contributing area is delineated from a Multiple-Flow Direction algorithm.

The downslope component :math:`D_{dn}` is given by:

.. math:: D_{dn}=\sum_i\frac{d_i}{C_i S_i}
    :label: d_dn

where :math:`d_i` is the length of the flow path along the ith cell according to the steepest downslope direction (:math:`m`) (see Figure 2), :math:`C_i` and :math:`S_i` are the :math:`C` factor and the slope gradient of the ith cell, respectively. Again, the downslope flow path is determined from a Multiple-Flow Direction algorithm.

To avoid infinite values for :math:`IC`, slope values :math:`S` are forced to a minimum of 0.005 m/m if they occur to be less than this threshold, and an upper limit of 1 m/m to limit bias due to very high values of :math:`IC` on steep slopes. (Cavalli et al., 2013).

**Step 2.** The SDR ratio for a pixel :math:`i` is then derived from the conductivity index :math:`IC` following (Vigiak et al., 2012):

.. math:: SDR_i = \frac{SDR_{max}}{1+\exp\left(\frac{IC_0-IC_i}{k}\right)}
    :label: sdr

where :math:`SDR_{max}` is the maximum theoretical SDR, set to an average value of 0.8 (Vigiak et al., 2012), and :math:`IC_0` and :math:`k` are calibration parameters that define the shape of the SDR-IC relationship (which is an increasing function). The effect of :math:`IC_0` and :math:`k` on the SDR is illustrated below:

.. figure:: ./sdr/ic0_k_effect.png

Figure 3. Relationship between the connectivity index IC and the SDR. The maximum value of SDR is set to :math:`SDR_{max}=0.8`. The effect of the calibration are illustrated by setting :math:`k_b=1` and :math:`k_b=2` (solid and dashed line, respectively), and :math:`IC_0=0.5` and :math:`IC_0=2` (black and grey dashed lines, respectively).

Sediment Export
^^^^^^^^^^^^^^^

The sediment export from a given pixel i :math:`E_i` (units: :math:`tons\cdot ha^{-1} yr^{-1}`), is the amount of sediment eroded from that pixel that actually reaches the stream. Sediment export is given by:

.. math:: E_i=usle_i\cdot SDR_i
    :label: e_i

The total catchment sediment export :math:`E` (units: :math:`ton\cdot ha^{-1} yr^{-1}`) is given by:

.. math:: E=\sum_i E_i
    :label: e

:math:`E` is the value used for calibration/validation purposes, in combination with other sediment sources, if data are available.

Sediment Downslope Deposition
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This model also makes an estimate of the amount of sediment that is deposited on the landscape downstream from the source that does not reach the stream. Knowing the spatial distribution of this quantity will allow users to track net change of sediment on a pixel (gain or loss) which can inform land degradation indices.

Sediment export to stream from pixel :math:`i` is defined in equation :eq:`e_i`. The other component of the mass balance from the USLE is that sediment which does not reach the stream. This sediment load must be deposited somewhere on the landscape along the flowpath to the stream and is defined as follows

.. math:: E'_i=usle_i (1-SDR_i)
    :label: eprime

Due to the nature of the calculation of SDR, the quantity :math:`E_i` has accounted for the downstream flow path and biophysical properties that filter sediment to stream. Thus, we can model the flow of :math:`E'_i` downstream independently of the flow of :math:`E_i`.

To do this, we assume the following properties about how :math:`E_i` and SDR behave across a landscape:

**Property A**: SDR monotonically increases along a downhill flowpath:  As a flowpath is traced downhill, the value of SDR will monotonically increase since amount of downstream flow distance decreases. Note there is the numerical possibility that a downstream pixel has the same SDR value as an upstream pixel. The implication in this case is that no on-pixel sediment flux deposition occurs along that step.

**Property B**: All non-exporting sediment flux on a boundary stream pixel is retained by that pixel: If pixel :math:`i` drains directly to the stream there is no opportunity for further downstream filtering of :math:`E_i`. Since :math:`E_i` is the inverse of Ei, the implication is that the upstream flux (defined as Fi below) must have been deposited on the pixel.

Given these two properties, we see that the amount of :math:`E_i` retained on a pixel must be a function of:

 * the absolute difference in SDR values from pixel :math:`i` to the downstream pixel(s) drain, and
 * how numerically close the downstream SDR value is to 1.0 (the stream pixel).

These mechanics can be captured as a linear interpolation of the difference of pixel i's SDR value with its downstream SDR counterpart with respect to the difference of pixel i's difference with a theoretical maximum downstream SDR value 1.0. Formally,

.. math:: dR_i=\frac{\sum_{k \in \{directly\ downstream\ from\ i\}}SDR_k\cdot p(i,k) - SDR_i}{1.0-SDR_i}
    :label: dri

The :math:`d` in :math:`dR_i` indicates a delta difference and :math:`p(i,k)` is the proportion of flow from pixel :math:`i` to pixel :math:`j`. This notation is meant to invoke the intution of a derivative of :math:`Ri`. Note the boundary conditions are satisfied:

 * In the case of Property A (downstream :math:`SDR_k=SDR_i`), the value of :math:`dR_i=0` indicating no :math:`F_i` will be retained on the pixel.
 * In the case of Property B (downstream :math:`SDR_k=1` because it is a stream) the value of :math:`dR_i=1` indicating the remaining :math:`F_i` is retained on the pixel.

Now we define the amount of sediment flux that is retained on any pixel in the flowpath using :math:`dR_i` as a weighted flow of upstream flux:

.. math:: R_i=dR_i\cdot\left(\sum_{j\in\{pixels\ that\ drain\ to\ i\}}F_j p(i,j)+E'_i\right)
    :label: ri

where :math:`F_j` is the amount of sediment-export-that-does-not-reach-the stream "flux", defined as:

.. math:: F_i=(1-dR_i)\cdot\left(\sum_{j\in\{pixels\ that\ drain\ to\ i\}} F_j p(i,j)+E'_i\right)
    :label: fi

Optional Drainage Layer
^^^^^^^^^^^^^^^^^^^^^^^

In some situations, the index of connectivity defined by topography does not represent actual flow paths, which may be influenced by artificial connectivity instead. For example, sediments in urban areas or near roads are likely to be conveyed to the stream with little retention. The (optional) drainage raster identifies the pixels that are artificially connected to the stream, irrespective of their geographic position (e.g. their distance to the stream network). Pixels from the drainage layer are treated similarly to pixels of the stream network; in other words, the downstream flow path will stop at pixels of the drainage layer (and the corresponding sediment load will be added to the total sediment export).


Limitations
-----------

 * Among the main limitations of the model is its reliance on the USLE (Renard et al., 1997). This equation is widely used but is limited in scope, only representing rill/inter-rill erosion processes. Other sources of sediment include gully erosion, streambank erosion, and mass erosion. A good description of the gully and streambank erosion processes is provided by Wilkinson et al. 2014, with possible modeling approaches. Mass erosion (landslide) is not represented in the model but can be a significant source in some areas or under certain land use change, such as road construction.

 * A corollary is that the descriptions of the impact on ecosystem services (and any subsequent valuation) should account for the relative proportion of the sediment source from the model compared to the total sediment budget (see the section on **Evaluating sediment retention services**).

 * In addition, as an empirical equation developed in the United States, the USLE has shown limited performance in other areas – even when focusing on sheet and rill erosion. Based on local knowledge, users may modify the soil loss equation implemented in the model by altering the R, K, C, P inputs to reflect findings from local studies (Sougnez et al., 2011).

 * The model is very sensitive to the *k* and *IC0* parameters, which are not physically based. The emerging literature on the modeling approach used in the InVEST model (Cavalli et al., 2013; López-vicente et al., 2013; Sougnez et al., 2011; Vigiak et al., 2012) provides guidance to set these parameters, but users should be aware of this limitation when interpreting the model's absolute values.

 * Given the simplicity of the model and low number of parameters, outputs are very sensitive to most input parameters. Errors in the empirical parameters of the USLE equations will therefore have a large effect on predictions. Sensitivity analyses are recommended to investigate how the confidence intervals in input parameters affect the study conclusions.


Differences between the InVEST SDR model and the original approach developed by Borselli et al. (2008)
------------------------------------------------------------------------------------------------------

The InVEST SDR model is based on the concept of hydrological connectivity, as parameterized by Borselli et al. (2012). This approach was selected since it requires a minimal number of parameters, uses globally available data, and is spatially explicit.  In a comparative study, Vigiak et al. (2012) suggested that the approach provides: "(i) large improvement in predicting specific sediment yields, (ii) ease of implementation, (iii) scale-independency; and (iv) a formulation capable of accounting for landscape variables and topology in line with sedimentological connectivity concepts". The approach has also been used to predict the effect of land use change (Jamshidi et al., 2013).

The following points summarize the differences between InVEST and the Borselli model:

 * The weighting factor is directly implemented as the USLE C factor (other researchers have used a different formulation, e.g. roughness index based on a high-resolution DEM (Cavalli et al., 2013))

 * The :math:`SDR_{max}` parameter used by Borselli et al. is set to 0.8 by default to reduce the number of parameters. Vigiak et al. (2012) propose to define :math:`SDR_{max}` as the fraction of topsoil particles finer than coarse sand (<1 mm).

Evaluating Sediment Retention Services
======================================

Sediment Retention Services
---------------------------

Translating the biophysical impacts of altered sediment delivery to human well-being metrics depends very much on the decision context. Soil erosion, suspended sediment and deposited sediment can have both negative and positive impacts on various users in a watershed (Keeler et al, 2012). These include, but are not limited to:

 * Reduced soil fertility and reduced water and nutrient holding capacity, impacting farmers
 * Increase in treatment costs for drinking water supply
 * Reduced lake clarity diminishing the value of recreation
 * Increase in total suspended solids impacting health and distribution of aquatic populations
 * Increase in reservoir sedimentation diminishing reservoir performance or increasing sediment control costs
 * Increase in harbor sedimentation requiring dredging to preserve harbor function

Sediment Retention Index
^^^^^^^^^^^^^^^^^^^^^^^^

An index of sediment retention is computed by the model as follows:

.. math:: R_i\cdot K_i \cdot LS_i (1-C_i P_i) × SDR_i
    :label: retention_index

which represents the avoided soil loss by the current land use compared to bare soil, weighted by the SDR factor. This index underestimates retention since it does not account for the retention from upstream sediment flowing through the given pixel.  Therefore, this index should not be interpreted quantitatively. We also note that in some situations, index values may be counter-intuitive: for example, urban pixels may have a higher index than forest pixels if they are highly connected to the stream. In other terms, the SDR (second factor) can be high for these pixels, compensating for a lower service of avoided soil loss (the first factor): this suggests that the urban environment is already providing a service of reduced soil loss compared to an area of bare soil.

|

Quantitative Valuation
^^^^^^^^^^^^^^^^^^^^^^

An important note about assigning a monetary value to any service is that valuation should only be done on model outputs that have been calibrated and validated. Otherwise, it is unknown how well the model is representing the area of interest, which may lead to misrepresentation of the exact value. If the model has not been calibrated, only relative results should be used (such as an increase of 10%) not absolute values (such as 1,523 tons, or 42,900 dollars.)

**Sediment retention at the subwatershed level** From a valuation standpoint, an important metric is the difference in retention or yield across scenarios. For quantitative assessment of the retention service, the model uses as a benchmark a hypothetical scenario where all land is cleared to bare soil: the value of the retention service is then based on the difference between the sediment export from this bare soil catchment and that of the scenario of interest. This output is termed "sed_retent" in the watershed summary table and sed_retention.tif in the raster outputs. Similarly, the sediment retention provided by different user-provided scenarios may be compared with the baseline condition (or each other) by taking the difference in sediment export between scenario and baseline. This change in export can represent the change in sediment retention service due to the possible future reflected in the scenario.

**Additional sources and sinks of sediment** As noted in the model limitations, the omission of some sources and sinks of sediment (gully erosion, stream bank erosion, and mass erosion) should be considered in the valuation analyses. In some systems, these other sources of sediment may dominate and large changes in overland erosion may not make a difference to overall sediment concentrations in streams.  In other words, if the sediment yields from two scenarios differ by 50%, and the part of rill/inter-rill erosion in the sediment budget in 60%, then the actual change in erosion that should be valued for avoided reservoir sedimentation is 30% (50% x .6).

One complication when calculating the total sediment budget is that changes in climate or land use result in changes in peak flow during rain events, and are thus likely to affect the magnitude of gully and streambank erosion. While the magnitude of the change in other sediment sources is highly contextual, it is likely to be in the same direction as the change in overland erosion: a higher sediment overland transport is indeed often associated with higher flows, which likely increase gully and bank erosion. Therefore, when comparing across scenarios, the absolute change may serve as a lower bound on the total impact of a particular climate or land use change.

**Appendix 2** summarizes options to represent the additional sources and sinks of erosion in the model.

**Replacement and avoided cost frameworks, versus willingness to pay approaches** With many ecosystem service impacts, and sediment impacts in particular, monetary valuation is relatively simple if an avoided mitigation cost or replacement cost method is deemed appropriate. In this situation, beneficiaries are assumed to incur a cost that is a function of the biophysical metric (e.g., suspended sediment increases treatment costs). However, it is important to recognize that the avoided cost or replacement cost approaches assume the mitigating actions are worthwhile for the actor undertaking them. For example, if a reservoir operator deems that the costs associated with dredging deposited sediment are not worth the benefits of regaining lost storage capacity, it is not appropriate to value all deposited sediment at the unit cost of dredging. Similarly, an increase in suspended sediment for drinking water supplies may be met by increasing treatment inputs or switching to an alternate treatment technology. Avoiding these extra costs could then be counted as economic benefits. However, in some contexts, private water users may decide that the increase in sediment content is acceptable, rather than incur additional treatment expenses. They are economically worse off, but by not paying for additional treatment, the replacement cost approach becomes an upper bound on their economic loss. Their economic loss is also no longer captured by their change in financial expenditures, which further complicates the analysis.

Note, however, that this bounding approach may be entirely appropriate for initial assessment of the significance of different benefit streams, i.e. if the most expensive approach does not have a significant impact, then there is no need to refine the analysis to utilize more detailed approaches such as willingness-to-pay (for consumers) or impacts on net revenues (for producers). However, if the impact is large and there is no good reason to believe that the relevant actors will undertake the mitigating activities, then a willingness-to-pay framework is the appropriate path to take. For an introduction to the techniques available, see http://ecosystemvaluation.org/dollar_based.htm.

**Time considerations** Generally, economic and financial analysis will utilize some form of discounting that recognizes the time value of money, benefits, and use of resources. Benefits and costs that accrue in the future "count for less" than benefits and costs that are borne close to the present. It is important that any economic or financial analysis be cognizant of the fact that the SDR model represents only average annual impacts under steady state conditions. This has two implications for valuation. First, users must recognize that the impacts being valued may take some time to come about: It is not the case that the full steady state benefits would begin accruing immediately, even though many of the costs might. Second, the annual averaging means that cost or benefit functions displaying nonlinearities on shorter timescales should (if possible) be transformed, or the InVEST output should be paired with other statistical analysis to represent important intra- or inter-annual variability.

Data Needs
==========

This section outlines the specific data used by the model. See the Appendix for additional information on data sources and pre-processing. Please consult the InVEST sample data (located in the folder where InVEST is installed, if you also chose to install sample data) for examples of all of these data inputs. This will help with file type, folder structure and table formatting. Note that all GIS inputs must be in the same projected coordinate system and in linear meter units.

- **Workspace** (required). Folder where model outputs will be written. Make sure that there is ample disk space, and write permissions are correct.

- **Suffix** (optional). Text string that will be appended to the end of output file names, as "_Suffix". Use a Suffix to differentiate model runs, for example by providing a short name for each scenario. If a Suffix is not provided, or changed between model runs, the tool will overwrite previous results.

- **Digital elevation model (DEM)** (required). Raster dataset with an elevation value for each cell. Make sure the DEM is corrected by filling in sinks, and compare the output stream maps with hydrographic maps of the area. To ensure proper flow routing, the DEM should extend beyond the watersheds of interest, rather than being clipped to the watershed edge. [units: meters]

- **Rainfall erosivity index (R)** (required). Raster dataset, with an erosivity index value for each cell. This variable depends on the intensity and duration of rainfall in the area of interest. The greater the intensity and duration of the rain storm, the higher the erosion potential. The erosivity index is widely used, but in case of its absence, there are methods and equations to help generate a grid using climatic data. [units: :math:`MJ\cdot mm\cdot (ha\cdot h\cdot yr)^{-1}`]

- **Soil erodibility (K)** (required). Raster dataset, with a soil erodibility value for each cell. Soil erodibility, K, is a measure of the susceptibility of soil particles to detachment and transport by rainfall and runoff. [units: :math:`tons\cdot ha\cdot h\cdot (ha\cdot MJ\cdot mm)^{-1}`]

- **Land use/land cover (LULC)** (required). Raster dataset, with an integer LULC code for each cell. *All values in this raster MUST have corresponding entries in the Biophysical table.*

- **Watersheds** (required). A shapefile of polygons. This is a layer of watersheds such that each watershed contributes to a point of interest where water quality will be analyzed. Format: An integer field named *ws_id* is required, with a unique integer value for each watershed.

- **Biophysical table** (required). A .csv (Comma Separated Value) table containing model information corresponding to each of the land use classes in the LULC raster. *All LULC classes in the LULC raster MUST have corresponding values in this table.* Each row is a land use/land cover class and columns must be named and defined as follows:

    - **lucode**: Unique integer for each LULC class (e.g., 1 for forest, 3 for grassland, etc.) *Every value in the LULC map MUST have a corresponding lucode value in the biophysical table.*

    - **usle_c**: Cover-management factor for the USLE, a floating point value between 0 and 1.

    - **usle_p**: Support practice factor for the USLE, a floating point value between 0 and 1.

- **Threshold flow accumulation** (required). The number of upstream cells that must flow into a cell before it is considered part of a stream, which is used to classify streams from the DEM. This threshold directly affects the expression of hydrologic connectivity and the sediment export result: when a flow path reaches the stream, sediment deposition stops and the sediment exported is assumed to reach the catchment outlet. It is important to choose this value carefully, so modeled streams come as close to reality as possible. See Appendix 1 for more information on choosing this value. Integer value, with no commas or periods - for example "1000".

- :math:`k_b` and :math:`IC_0` (required): Two calibration parameters that determine the shape of the relationship between hydrologic connectivity (the degree of connection from patches of land to the stream) and the sediment delivery ratio (percentage of soil loss that actually reaches the stream; cf. Figure 3). The default values are :math:`k_b=2` and :math:`IC_0=0.5`.

- :math:`\mathbf{SDR_{max}}` (required): The maximum SDR that a pixel can reach, which is a function of the soil texture. More specifically, it is defined as the fraction of topsoil particles finer than coarse sand (1000 μm; Vigiak et al. 2012). This parameter can be used for calibration in advanced studies. Its default value is 0.8.

- :math:`\mathbf{l_{max}}` (required): The maximum allowed value of the L parameter when calculating the LS factor. Calculated values that exceed this are clamped to this value. Its default value is 122 but reasonable values in literature place it anywhere between 122-333 see Desmet and Govers, 1996 and Renard et al., 1997.

- **Drainage layer (optional)** A raster with 0s and 1s, where 1s correspond to pixels artificially connected to the stream (by roads, stormwater pipes, etc.) and 0s are assigned to all other pixels. The flow routing will stop at these "artificially connected" pixels, before reaching the stream network, and the corresponding sediment exported is assumed to reach the catchment outlet.


Running the Model
=================

To launch the Sediment model navigate to the Windows Start Menu -> All Programs -> InVEST [*version*] -> SDR. The interface does not require a GIS desktop, although the results will need to be explored with any GIS tool such as ArcGIS or QGIS.


Interpreting Results
--------------------

The following is a short description of each of the outputs from the SDR model. Final results are found within the user defined Workspace specified for this model run. "Suffix" in the following file names refers to the optional user-defined Suffix input to the model.

The resolution of the output rasters will be the same as the resolution of the DEM provided as input.


* **[Workspace]** folder:

    * **Parameter log**: Each time the model is run, a text (.txt) file will be created in the Workspace. This file will list the parameter values and output messages for that run and will be named according to the service, the date and time, and the suffix. When contacting NatCap about errors in a model run, please include the parameter log.

    * **rkls_[Suffix].tif** (type: raster; units: tons/pixel): Total potential soil loss per pixel in the original land cover without the C or P factors applied from the RKLS equation. Equivalent to the soil loss for bare soil.

    * **sed_export_[Suffix].tif** (type: raster; units: tons/pixel): The total amount of sediment exported from each pixel that reaches the stream.

    * **sediment_deposition_[Suffix].tif** (type: raster; units: tons/pixel): The total amount of sediment deposited on the pixel from upstream sources as a result of retention.

    * **stream_[Suffix].tif** (type: raster): Stream network generated from the input DEM and Threshold Flow Accumulation. Values of 1 represent streams, values of 0 are non-stream pixels. Compare this layer with a real-world stream map, and adjust the Threshold Flow Accumulation so that **stream.tif**  matches real-world streams as closely as possible.

    * **stream_and_drainage_[Suffix].tif** (type: raster): If a drainage layer is provided, this raster is the union of that layer with the calculated stream layer.

    * **usle_[Suffix].tif** (type: raster; units: tons/pixel): Total potential soil loss per pixel in the original land cover calculated from the USLE equation.

    * **sed_retention_[Suffix].tif** (type:raster; units: tons/pixel): Map of sediment retention with reference to a watershed where all LULC types are converted to bare ground.

    * **sed_retention_index_[Suffix].tif** (type: raster; units: tons/pixel, but should be interpreted as relative values, not absolute): Index of sediment retention, used to identified areas contributing more to retention with reference to a watershed where all LULC types are converted to bare ground. This is NOT the sediment retained on each pixel (see Section on the index in "Evaluating Sediment Retention Services" above).

    * **watershed_results_sdr_[Suffix].shp**: Table containing biophysical values for each watershed, with fields as follows:

        * **sed_export** (units: tons/watershed): Total amount of sediment exported to the stream per watershed. This should be compared to any observed sediment loading at the outlet of the watershed. Knowledge of the hydrologic regime in the watershed and the contribution of the sheetwash yield into total sediment yield help adjust and calibrate this model.

        * **usle_tot** (units: tons/watershed): Total amount of potential soil loss in each watershed calculated by the USLE equation.

        * **sed_retent** (units: tons/watershed): Difference in the amount of sediment delivered by the current watershed and a hypothetical watershed where all land use types have been converted to bare ground.

        * **sed_dep** (units: tons/watershed): Total amount of sediment deposited on the landscape in each watershed, which does not enter the stream.

* **[Workspace]\\intermediate_outputs** folder:

    * slope, thresholded_slope, flow_direction, flow_accumulation: hydrologic rasters based on the DEM used for flow routing (outputs from RouteDEM, see corresponding chapter in the User's Guide)

    * ls_[Suffix].tif -> LS factor for USLE (Eq. :eq:`ls`)

    * w_bar_[Suffix].tif -> mean weighting factor (C factor) for upslope contributing area

    * s_bar_[Suffix].tif -> mean slope factor for upslope contributing area

    * d_up_[Suffix].tif (and bare_soil) -> upslope factor of the index of connectivity (Eq. :eq:`d_up`)

    * w_[Suffix].tif -> denominator of the downslope factor (Eq. :eq:`d_dn`)

    * d_dn_[Suffix].tif (and bare_soil) -> downslope factor of the index of connectivity (Eq. :eq:`d_dn`)

    * ic_[Suffix].tif (and bare_soil) -> index of connectivity (Eq. :eq:`ic`)

    * sdr_factor_[Suffix].tif (and bare_soil) -> sediment delivery ratio (Eq. :eq:`sdr`)

    * weighted_avg_flow_[Suffix].tif -> the mean proportional flow weighted by the flow length for all neighbor pixels.


Comparison with Observations
----------------------------

The sediment yield (sed_export) predicted by the model can be compared with available observations. These can take the form of sediment accumulation in a reservoir or time series of Total Suspended Solids (TSS) or turbidity. In the former case, the units are the same as in the InVEST model (tons per year). For time series, concentration data need to be converted to annual loads (LOADEST and FLUX32 are two software facilitating this conversion). Time series of sediment loading used for model validation should span over a reasonably long period (preferably at least 10 years) to attenuate the effect of inter-annual variability. Time series should also be relatively complete throughout a year (without significant seasonal data gaps) to ensure comparison with total annual loads.

A global database of sediment yields for large rivers can be found on the FAO website: http://www.fao.org/nr/water/aquastat/sediment/index.stm
Alternatively, for large catchments, global sediment models can be used to estimate the sediment yield. A review of such models was performed by de Vente et al. (2013).

A key thing to remember when comparing modeled results to observations is that the model represents rill-inter-rill erosion only. As indicated in the Introduction three other sources of sediment may contribute to the sediment budget: gully erosion, stream bank erosion, and mass erosion. The relative importance of these processes in a given landscape needs to be determined to ensure appropriate model interpretation.

For more detailed information on comparing with observations, and associated calibration, see Hamel et al (2015).

If there are dams on streams in the analysis area, it is possible that they are retaining sediment, such that it will not arrive at the outlet of the study area. In this case, it may be useful to adjust for this retention when comparing model results with observed data. For an example of how this was done for a study in the northeast U.S., see Griffin et al 2020. The dam retention methodology is described in the paper's Appendix, and requires knowing the sediment trapping efficiency of the dam(s).


Appendix 1: Data Sources
========================

This is a rough compilation of data sources and suggestions about finding, compiling, and formatting data, providing links to global datasets that can get you started. It is highly recommended to look for more local and accurate data (from national, state, university, literature, NGO and other sources) and only use global data for final analyses if nothing more local is available.

Digital Elevation Model (DEM)
-----------------------------

DEM data is available for any area of the world, although at varying resolutions.

Free raw global DEM data is available from:

 *  The World Wildlife Fund - https://www.worldwildlife.org/pages/hydrosheds
 *  NASA: \ https://asterweb.jpl.nasa.gov/gdem.asp (30m resolution); and easy access to SRTM data: \ http://dwtkns.com/srtm/
 *  USGS: \ https://earthexplorer.usgs.gov/


Alternatively, it may be purchased relatively inexpensively at sites such as MapMart (www.mapmart.com).

The DEM resolution may be a very important parameter depending on the project's goals. For example, if decision makers need information about impacts of roads on ecosystem services then fine resolution is needed. The hydrological aspects of the DEM used in the model must be correct. Most raw DEM data has errors, so it's likely that the DEM will need to be filled to remove sinks. The QGIS Wang & Liu Fill algorithm (SAGA library) or ArcGIS Fill tool have shown good results. Look closely at the stream network produced by the model (**stream.tif**.) If streams are not continuous, but broken into pieces, the DEM still has sinks that need to be filled. If filling sinks multiple times does not create a continuous stream network, perhaps try a different DEM. If the results show an unexpected grid pattern, this may be due to reprojecting the DEM with a "nearest neighbor" interpolation method instead of "bilinear" or "cubic". In this case, go back to the raw DEM data and reproject using "bilinear" or "cubic".

Also see the User Guide section **Getting Started > Working with the DEM** for more guidance about preparing this layer.


Rainfall Erosivity Index (R)
----------------------------

R should be obtained from published values, as calculation is very tedious. For calculation, R equals the annual average of EI values, where E is the kinetic energy of rainfall (in :math:`MJ\cdot ha^{-1}`) and I30 is the maximum intensity of rain in 30 minutes (in mm.hr-1).  A review of relationships between precipitation and erosivity index around the world is provided by Renard and Freimund (1994).

General guidance to calculate the R index can be found in the FAO Soils bulletin 70 (Roose, 1996): http://www.fao.org/3/t1765e/t1765e0e.htm. It is also possible that area- or country-specific equations for R have been derived, so it is worth doing a literature search for these.

A global map of rainfall erosivity (30 arc-seconds, ~1km at the equator) is available from the European Commission: https://esdac.jrc.ec.europa.eu/content/global-rainfall-erosivity.

In the United States, national maps of the erosivity index can be found through the United States Department of Agriculture (USDA) and Environmental Protection Agency (EPA) websites. The USDA published a soil loss handbook (https://www3.epa.gov/npdes/pubs/ruslech2.pdf ) that contains a hard copy map of the erosivity index for each region. Using these maps requires creating a new line feature class in GIS and converting to raster. Please note that conversion of units is also required: multiplication by 17.02 is needed to convert from US customary units to MJ.mm.(ha.h.yr)-1, as detailed in Appendix A of the USDA RUSLE handbook (Renard et al., 1997).

The EPA has created a digital map that is available at https://archive.epa.gov/esd/archive-nerl-esd1/web/html/wemap_mm_sl_rusle_r_qt.html. The map is in a shapefile format that needs to be converted to raster, along with an adjustment in units.

Soil Erodibility (K)
--------------------

Texture is the principal factor affecting K, but soil profile, organic matter and permeability also contribute. It varies from 70/100 for the most fragile soil to 1/100 for the most stable soil (in US customary units). Erodibility is typically measured on bare reference plots, 22.2 m-long on 9% slopes, tilled in the direction of the slope and having received no organic matter for three years.

Global soil data are available from the Soil and Terrain Database (SOTER) Programme (https://data.isric.org:443/geonetwork/srv/eng/catalog.search). They provide some area-specific soil databases, as well as SoilGrids globally.

The FAO also provides global soil data in their Harmonized World Soil Database: https://webarchive.iiasa.ac.at/Research/LUC/External-World-soil-database/HTML/, but it is rather coarse.

In the United States free soil data is available from the U.S. Department of Agriculture's NRCS gSSURGO, SSURGO and gNATSGO databases: https://www.nrcs.usda.gov/wps/portal/nrcs/main/soils/survey/geo/. They also provide ArcGIS tools (Soil Data Viewer for SSURGO and Soil Data Development Toolbox for gNATSGO) that help with processing these databases into spatial data that can be used by the model. The Soil Data Development Toolbox is easiest to use, and highly recommended if you use ArcGIS and need to process U.S. soil data.

Please note that conversion of units may be required: multiplication by 0.1317 is needed to convert from US customary units to :math:`ton\cdot ha\cdot hr\cdot (ha\cdot MJ\cdot mm)^{-1}`, as detailed in Appendix A of the USDA RUSLE handbook (Renard et al., 1997).

Alternatively, the following equation can be used to calculate K (Renard et al., 1997):

.. math:: K = \frac{2.1\cdot 10^{-4}(12-a)M^{1.14}+3.25(b-2)+2.5(c-3)}{759}
    :label: k

In which K = soil erodibility factor (:math:`t\cdot ha\cdot hr\cdot (MJ\cdot mm\cdot ha)^{-1}`; M = (silt (%) + very fine sand (%))(100-clay (%)) a = organic matter (%) b = structure code: (1) very structured or particulate, (2) fairly structured, (3) slightly structured and (4) solid c = profile permeability code: (1) rapid, (2) moderate to rapid, (3) moderate, (4) moderate to slow, (5) slow and (6) very slow.

When profile permeability and structure are not available, soil erodibility can be estimated based on soil texture and organic matter content, based on the work of Wischmeier, Johnson and Cross (reported in Roose, 1996). The OMAFRA fact sheet summarize these values in the following table (http://www.omafra.gov.on.ca/english/engineer/facts/12-051.htm):

.. csv-table::
  :file: sdr/soil_data.csv
  :header-rows: 1
  :name: OMAFRA Fact Sheet

**The soil erodibility values (K) in this table are in US customary units, and require the 0.1317 conversion mentioned above.** Values are based on the OMAFRA Fact sheet. Soil textural classes can be derived from the FAO guidelines for soil description (FAO, 2006, Figure 4).

A special case is the K value for water bodies, for which soil maps may not indicate any soil type. A value of 0 can be used, assuming that no soil loss occurs in water bodies.

Sometimes, soil maps may also have holes in places that aren't water bodies (such as glaciers.) Here, look at a land cover map to see what is happening on the landscape. If it is a place where erosion is unlikely to happen (such as rock outcrops), a value of 0 may be used. However, if the area seems like it should have soil data, you can use a nearest neighbor GIS function, or manually set those areas to the dominant soil type that surrounds the missing data.

Land Use/Land Cover
-------------------

A key component for all water models is a spatially continuous land use/land cover (LULC) raster, where all pixels must have a land use/land cover class defined. Gaps in data will create missing data (holes) in the output layers. Unknown data gaps should be approximated.

Global land use data is available from:

 *  NASA: https://lpdaac.usgs.gov/products/mcd12q1v006/ (MODIS multi-year global landcover data provided in several classifications)
 *  The European Space Agency: http://www.esa-landcover-cci.org/ (Three global maps for the 2000, 2005 and 2010 epochs)

Data for the U.S. is provided by the USGS and Department of the Interior via the National Land Cover Database: https://www.usgs.gov/centers/eros/science/national-land-cover-database

The simplest categorization of LULCs on the landscape involves delineation by land cover only (e.g., cropland, forest, grassland). Several global and regional land cover classifications are available (e.g., Anderson et al. 1976), and often detailed land cover classification has been done for the landscape of interest. Many countries have national LULC maps that can be used.

A slightly more sophisticated LULC classification involves breaking relevant LULC types into more meaningful types. For example, agricultural land classes could be broken up into different crop types or forest could be broken up into specific species. The categorization of land use types depends on the model and how much data is available for each of the land types. You should only break up a land use type if it will provide more accuracy in modeling. For instance, only break up 'crops' into different crop types if you have information on the difference in USLE C values between crops.

P and C Coefficients
--------------------

The support practice factor, P, accounts for the effects of contour plowing, strip-cropping or terracing relative to straight-row farming up and down the slope. The cover-management factor, C, accounts for the specified crop and management relative to tilled continuous fallow. These values will need to be obtained from a literature search. Several references on estimating these factors can be found online:

 * USDA: RUSLE handbook (Renard et al., 1997)

 * OMAFRA: USLE Fact Sheet http://www.omafra.gov.on.ca/english/engineer/facts/12-051.htm

 * U.N. Food and Agriculture Organization http://www.fao.org/3/T1765E/t1765e0c.htm

Watersheds / Subwatersheds
--------------------------

To delineate watersheds, we provide the InVEST tool DelineateIT, which is relatively simple yet fast and has the advantage of creating watersheds that might overlap, such as watersheds draining to several dams on the same river. See the User Guide chapter for DelineateIt for more information on this tool. Watershed creation tools are also provided with GIS software, as well as some hydrology models. It is recommended that you delineate watersheds using the DEM that you are modeling with, so the watershed boundary corresponds correctly to the topography.

Alternatively, a number of watershed maps are available online, e.g. HydroBASINS: https://hydrosheds.org/. Note that if watershed boundaries are not based on the same DEM that is being modeled, results that are aggregated to these watersheds are likely to be inaccurate.

Exact locations of specific structures, such as reservoirs, should be obtained from the managing entity or may be obtained on the web:

 * The U.S. National Inventory of Dams: https://nid.sec.usace.army.mil/

 * Global Reservoir and Dam (GRanD) Database: http://globaldamwatch.org/grand/

 * World Water Development Report II dam database: https://wwdrii.sr.unh.edu/download.html

Some of these datasets include the catchment area draining to each dam, which should be compared with the area of the watershed(s) generated by the delineation tool to assess accuracy.

Threshold flow accumulation
---------------------------

There is no one "correct" value for the threshold flow accumulation (TFA). The correct value for your application is the value that causes the model to create a stream layer that looks as close as possible to the real-world stream network in the watershed. Compare the model output file *stream.tif* with a known correct stream map, and adjust the TFA accordingly - larger values of TFA will create a stream network with fewer tributaries, smaller values of TFA will create a stream network with more tributaries. A good value to start with is 1000, but note that this can vary widely depending on the resolution of the DEM, local climate and topography. Note that generally streams delineated from a DEM do not exactly match the real world, so just try to come as close as possible. If the modelled streams are very different, then consider trying a different DEM. This is an integer value, with no commas or periods - for example "1000".

A global layer of streams can be obtained from HydroSHEDS: https://hydrosheds.org/, but note that they are generally more major rivers and may not include those in your study area, especially if it has small tributaries. You can also try looking at streams in Google Earth if no more localized maps are available.

Calibration Parameters :math:`IC_0` and :math:`k_b`
---------------------------------------------------

:math:`IC_0` and :math:`k_b` are calibration parameters that define the relationship between the index of connectivity and the sediment delivery ratio (SDR). Vigiak et al. (2012) suggest that :math:`IC_0` is landscape independent and that the model is more sensitive to :math:`k_b` . Advances in sediment modeling science should refine our understanding of the hydrologic connectivity and help improve this guidance. In the meantime, following other authors (Jamshidi et al., 2013), we recommend setting these parameters to their default values ( :math:`IC_0` =0.5 and :math:`k_b` =2), and using :math:`k_b` only for calibration (Vigiak et al., 2012).

For more detailed information on sensitivity analysis and calibration, see Hamel et al (2015).



Appendix 2: Representation of Additional Sources and Sinks of Sediment
======================================================================

The InVEST model predicts the sediment delivery only from sheetflow erosion, thus neglecting other sources and sinks of sediment (e.g. gully erosion, streambank, landslides, stream deposition, etc.), which can affect the valuation approach. Adding these elements to the sediment budget requires good knowledge of the sediment dynamics of the area and is typically beyond the scope of ecosystem services assessments. General formulations for instream deposition or gully formation are still an area of active research, with modelers systematically recognizing large uncertainties in process representation (Hughes and Prosser, 2003; Wilkinson et al., 2014). Consultation of the local literature to estimate the relative importance of additional sources and sinks is a more practical approach to assess their effect on the valuation approach.

.. csv-table::
  :file: sdr/sources_sinks.csv
  :header-rows: 1
  :name: Sources and Sinks of Sediment

If you are interested in modeling in-stream processes of sediment deposition or erosion, two possibilities are CASCADE (Schmitt 2016) or Czuba 2018. Both modeling frameworks are open source, and are good if you are interested in entire river networks. If you are more interested in deposition/erosion for a smaller channel section, one option is BASEMENT (https://basement.ethz.ch/).


References
==========

Bhattarai, R., Dutta, D., 2006. Estimation of Soil Erosion and Sediment Yield Using GIS at Catchment Scale. Water Resour. Manag. 21, 1635–1647.

Borselli, L., Cassi, P., Torri, D., 2008. Prolegomena to sediment and flow connectivity in the landscape: A GIS and field numerical assessment. Catena 75, 268–277.

Cavalli, M., Trevisani, S., Comiti, F., Marchi, L., 2013. Geomorphometric assessment of spatial sediment connectivity in small Alpine catchments. Geomorphology 188, 31–41.

Czuba, J.A., 2018. A Lagrangian framework for exploring complexities of mixed-size sediment transport in gravel-bedded river networks. Geomorphology 321, 146–152. https://doi.org/10.1016/j.geomorph.2018.08.031

Desmet, P.J.J., Govers, G., 1996. A GIs procedure for automatically calculating the USLE LS factor on topographically complex landscape units. J. Soi 51, 427–433.

De Vente J, Poesen J, Verstraeten G, Govers G, Vanmaercke M, Van Rompaey, A., Boix-Fayos C., 2013. Predicting soil erosion and sediment yield at regional scales: Where do we stand? Earth-Science Rev. 127 16–29

FAO, 2006. Guidelines for soil description - Fourth edition. Rome, Italy.

Robert Griffin, Adrian Vogl, Stacie Wolny, Stefanie Covino, Eivy Monroy, Heidi Ricci, Richard Sharp, Courtney Schmidt, Emi Uchida, 2020. "Including Additional Pollutants into an Integrated Assessment Model for Estimating Nonmarket Benefits from Water Quality," Land Economics, University of Wisconsin Press, vol. 96(4), pages 457-477. DOI: 10.3368/wple.96.4.457

Hamel, P., Chaplin-Kramer, R., Sim, S., Mueller, C. 2015. A new approach to modeling the sediment retention service (InVEST 3.0): Case study of the Cape Fear catchment, North Carolina, USA. Science of the Total Environment 524–525 (2015) 166–177.

Hughes, A.O., Prosser, I.P., 2003. Gully and Riverbank erosion mapping for the Murray-Darling Basin. Canberra, ACT.

Jamshidi, R., Dragovich, D., Webb, A.A., 2013. Distributed empirical algorithms to estimate catchment scale sediment connectivity and yield in a subtropical region. Hydrol. Process.

Lopez-vicente, M., Poesen, J., Navas, A., Gaspar, L., 2013. Predicting runoff and sediment connectivity and soil erosion by water for different land use scenarios in the Spanish Pre-Pyrenees. Catena 102, 62–73.

Oliveira, A.H., Silva, M.A. da, Silva, M.L.N., Curi, N., Neto, G.K., Freitas, D.A.F. de, 2013. Development of Topographic Factor Modeling for Application in Soil Erosion Models, in: Intechopen (Ed.), Soil Processes and Current Trends in Quality Assessment. p. 28.

Pelletier, J.D., 2012. A spatially distributed model for the long-term suspended sediment discharge and delivery ratio of drainage basins 117, 1–15.

Renard, K., Foster, G., Weesies, G., McCool, D., Yoder, D., 1997. Predicting Soil Erosion by Water: A Guide to Conservation Planning with the revised soil loss equation.

Renard, K., Freimund, J., 1994. Using monthly precipitation data to estimate the R-factor in the revised USLE. J. Hydrol. 157, 287–306.
Roose, 1996. Land husbandry - Components and strategy. Soils bulletin 70. Rome, Italy.

Schmitt, R.J.P., Bizzi, S., Castelletti, A., 2016. Tracking multiple sediment cascades at the river network scale identifies controls and emerging patterns of sediment connectivity. Water Resour. Res. 3941–3965. https://doi.org/10.1002/2015WR018097

Sougnez, N., Wesemael, B. Van, Vanacker, V., 2011. Low erosion rates measured for steep , sparsely vegetated catchments in southeast Spain. Catena 84, 1–11.

Vigiak, O., Borselli, L., Newham, L.T.H., Mcinnes, J., Roberts, A.M., 2012. Comparison of conceptual landscape metrics to define hillslope-scale sediment delivery ratio. Geomorphology 138, 74–88.

Wilkinson, S.N., Dougall, C., Kinsey-Henderson, A.E., Searle, R.D., Ellis, R.J., Bartley, R., 2014. Development of a time-stepping sediment budget model for assessing land use impacts in large river basins. Sci. Total Environ. 468-469, 1210–24.

