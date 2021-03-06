.. primer
.. _ucm:

*******************
Urban Cooling Model
*******************

Summary
=======

Urban heat mitigation is a priority for many cities that have undergone heat waves in recent years. Vegetation can help reduce the urban heat island by providing shade, modifying thermal properties of the urban fabric, and increasing cooling through evapotranspiration. This has consequences for health and wellbeing of citizens through reduced mortality and morbidity, increased comfort and productivity, and reduced need for air conditioning (A/C). The InVEST urban cooling model calculates an index of heat mitigation based on shade, evapotranspiration, and albedo, as well as distance from cooling islands (e.g. parks). The index is used to estimate a temperature reduction by vegetation. Finally, the model estimates the value of the heat mitigation service using two (optional) valuation methods: energy consumption and work productivity.

Introduction
============

The urban heat island effect affects many cities around the world, with major consequences on human health and wellbeing: high mortality or morbidity during heat waves, high A/C consumption, and reduced comfort or work productivity. The urban heat island effect, i.e. the difference between rural and urban temperatures, is caused by a change in the energy balance in cities due to two main factors: the thermal properties of materials used in urban areas (e.g. concrete, asphalt), which store more heat, and the reduction of the cooling effect of vegetation (through shade and evapotranspiration).
Natural infrastructure therefore plays a role in reducing the urban heat island in cities. Using the rapidly-growing literature on urban heat modeling (Deilami et al., 2018), the InVEST urban cooling model estimates the cooling effect of vegetation based on commonly available data on climate, land use/ land cover, and (optionally) A/C use.

The Model
=========

How it works
------------

Cooling capacity index
^^^^^^^^^^^^^^^^^^^^^^

The model first computes the cooling capacity index for each pixel based on local shade, evapotranspiration, and albedo. This approach is based on the indices proposed by Zardo et al. 2017 and Kunapo et al. 2018, to which we add albedo, an important factor for heat reduction.
The shade factor ('shade') represents the proportion of tree canopy (for trees >2m) associated with each LULC category. Its value is comprised between 0 and 1.
The evapotranspiration index represents a normalized value of potential evapotranspiration, i.e. the evapotranspiration from vegetation (or evaporation from soil, for unvegetated areas). It is calculated for each pixel by multiplying the reference evapotranspiration (:math:`ET0`, provided by the user) and the crop coefficient (:math:`Kc` , associated with the LULC type), and dividing by the maximum value of the :math:`ET0` raster in the area of interest, :math:`ETmax`.:

.. math:: ETI = \frac{K_c \cdot ET0}{ET_{max}}
    :label: eti

Note that this equation assumes that vegetated areas are sufficiently irrigated (although Kc values can be reduced to represent water-limited evapotranspiration).

The albedo factor is a value between 0 and 1 representing the proportion of solar radiation reflected by the LULC type (Phelan et al. 2015).

The model combines the three factors in the cooling capacity (CC) index:

.. math:: CC_i = 0.6 \cdot shade + 0.2\cdot albedo + 0.2\cdot ETI
    :label: coolingcapacity_factors

The default weighting (0.6; 0.2; 0.2) is based on empirical data and reflects the higher impact of shading compared to evapotranspiration. For example, Zardo et al. (2017) report that "in areas smaller than two hectares [evapotranspiration] was assigned a weight of 0.2 and shading of 0.8. In areas larger than two hectares the weights were changed to 0.6 and 0.4, for [evapotranspiration] and shading respectively". In the present model, we propose to disaggregate the effect of shade and albedo in Eq. 2, and give albedo equal weight to ETI based on the results by Phelan et al. (2015) (see Table 2 in their study showing that vegetation and albedo have similar coefficients).

Note: alternative weights can be manually entered by the user for testing the sensitivity of the model outputs to this parameter (or if local knowledge is available).

Optionally, the model can consider another factor, intensity (:math:`building.intensity` for a given landcover classifcation), which captures the vertical dimension of built infrastructure. Building intensity is an important predictor of night-time temperature since heat stored during the day is released by buildings during the night. To predict night-time temperatures, users need to provide the building intensity factor for each land use type in the Biophysical Table and the model will change equation :math:numref:`coolingcapacity_factors` to:

.. math:: CC_i = 1 - building.intensity
    :label: coolingcapacity_intensity


Urban heat mitigation index (effect of large green spaces)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To account for the cooling effect of large green spaces (>2 ha) on surrounding areas (see discussion in Zardo et al., 2017 and McDonald et al. 2016), the model calculates the urban heat mitigation (HM) index: HM is equal to CC if the pixel is unaffected by a large green spaces, and otherwise set to a distance-weighted average of the CC values from the large green space and the pixel of interest.

To do so, the model first computes the amount of green areas within a search distance :math:`d_{cool}` around each pixel (:math:`GA_i`), and the cooling capacity provided by each park (:math:`CC_{park_i}`):

.. math:: {GA}_{i}=cell_{area}\cdot\sum_{j\in\ d\ radius\ from\ i} g_{j}
    :label: [3a]

.. math:: CC_{park_i}=\sum_{j\in\ d\ radius\ from\ i} g_j \cdot CC_j \cdot e^{\left( \frac{-d(i,j)}{d_{cool}} \right)}
    :label: [3b]

where :math:`cell_{area}` is the area of a cell in ha, :math:`g_j` is 1 if pixel :math:`j` is green space, 0 otherwise, :math:`d(i,j)` is the distance between pixel :math:`i` and :math:`j`, :math:`d_{cool}` is the distance over which a green space has a cooling effect, and :math:`CC_{park_i}` is the distance weighted average of the CC values from green spaces. Note that LULC that count as "green area" are determined by the user with the parameter 'green_area' in the biophysical table, see Input table in Section 3. Then, the HM index is calculated as:

.. math:: HM_i = \begin{Bmatrix}
        CC_i & if & CC_i \geq CC_{park_i}\ or\ GA_i < 2 ha \\
        CC_{park_i} & & otherwise
        \end{Bmatrix}
    :label: [4]

Air temperature estimates
^^^^^^^^^^^^^^^^^^^^^^^^^

To estimate heat reduction throughout the city, the model uses the (city-scale) UHI magnitude, UHI_max. Users can obtain UHI values from local literature or global studies: for example, the Global surface UHI explorer developed by the university of Yale, provides estimates of annual, seasonal, daytime, and nighttime UHI (https://yceo.users.earthengine.app/view/uhimap).
Note that UHI magnitude is defined for a specific period (e.g. current or future climate) and time (e.g. nighttime or daytime temperatures). The selection of period and time will affect the service valuation.

Air temperature without air mixing :math:`T_{air_{nomix}}` is calculated for each pixel as:

.. math:: T_{air_{nomix},i}=T_{air,ref} + (1-HM_i)\cdot UHI_{max}
    :label: [5]

Where :math:`T_{air,ref}` is the rural reference temperature and :math:`UHI_{max}` is the magnitude of the UHI effect for the city.

Due to air mixing, these temperatures average spatially. Actual air temperature (with mixing), :math:`T_{air}`, is derived from :math:`T_{air_{nomix}}` using a Gaussian function with kernel radius :math:`r`, defined by the user.

For each area of interest (vector provided by the user), we calculate average temperature and temperature anomaly :math:`(T_{air,i} - T_{air,ref})`.

Value of heat reduction service
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The value of temperature reduction can be assessed in at least three ways:

    i) energy savings from reduced electricity consumption, when A/C is prevalent;
    ii) gain in work productivity for outdoor workers;
    iii) decrease in heat-related morbidity and mortality.

The model provides estimates of the first two, energy savings and work productivity, based on global regression analyses or local data.

Energy savings: the model uses a relationship between energy consumption and temperature (e.g. summarized by Santamouris et al., 2015), to calculate energy savings and associated costs for a building :math:`b`:

.. math:: Energy.savings(b)= consumption.increase(b) \cdot (\overline{T_{air,MAX} - T_{air,i}})
    :label: energy_savings_kwh

Where:

    * :math:`consumption.increase(b)` (kWh/degree C/:math:`m^2`) is the local estimate of the energy consumption increase per each degree of temperature per square meter of the building footprint, for building category :math:`b`.
    * :math:`T_{air,MAX}` (degC) is the maximum temperature over the landscape :math:`(T_{air,ref} + UHI_{max})`;
    * :math:`\overline{T_{air,MAX} - T_{air,i}}` (degC) is the average difference in air temperature for building :math:`b`, with :math:`T_{air,i}` modeled in the previous steps.


If costs are provided for each building category, equation :math:numref:`energy_savings_kwh` is replaced by equation :math:numref:`energy_savings_dollars`

.. math:: Energy.savings(b)= consumption.increase(b) \cdot (\overline{T_{air,MAX} - T_{air,i}}) \cdot cost(b)
    :label: energy_savings_dollars

Where:

    * :math:`cost(b)` is the estimate of energy cost per kWh for building category :math:`b`.  Note that this is very likely to be equal for all buildings.

To calculate total energy savings, we sum the pixel-level values over the area of interest.

Work Productivity: To calculate impacts of heat on work productivity, the model converts air temperature into Wet Bulb Globe Temperature (WBGT). This temperature takes into account humidity, and can be estimated from standard meteorological data in the following way (Source: American College of Sports Medicine, Prevention of thermal injuries during distance running - Position Stand. Med.J.Aust. 1984 Dec. 876 - see here):

.. math:: WBGT_i = 0.567 \cdot T_{air,i} + 0.393 \cdot e_i + 3.94
    :label: [7]

Where:

    * :math:`T_{air}` = temperature provided by the model (Dry bulb temperature (:math:`T_C` ))
    * :math:`e_i` = Water vapour pressure (hPa) [humidity]

The vapour pressure is calculated from the temperature and relative humidity using the equation:

.. math:: e_i = \frac{RH}{100} \cdot 6.105 \cdot e^{\left ( 17.27 \cdot \frac{T_{air,i}}{(237.7 + T_{air,i})} \right )}
    :label: [8]

Where:

    * :math:`RH` = average Relative Humidity [%] provided by the user

For each pixel, the model computes the estimated loss in productivity, in %, for two work intensities: "light work" and "heavy work" (based on rest time needed at different work intensities, as per Table 2 in Kjellstrom et al., 2009):

.. math:: Loss.light.work_i = \begin{Bmatrix}
        0 & if & WBGT < 31.5\\
        25 & if & 31.5 \leq WBGT < 32.0  \\
        50 & if & 32.0 \leq WBGT < 32.5 \\
        75 & if & 32.5 \leq WBGT \\
        \end{Bmatrix}
    :label: [9a]

.. math:: Loss.heavy.work_i = \begin{Bmatrix}
        0 & if & WBGT < 27.5\\
        25 & if & 27.5 \leq WBGT < 29.5  \\
        50 & if & 29.5 \leq WBGT < 31.5 \\
        75 & if & 31.5 \leq WBGT \\
        \end{Bmatrix}
    :label: [9b]

Here, "light work" corresponds to approx. 200 Watts metabolic rate, i.e.  office desk work and service industries, and "heavy work" corresponds to 400 W, i.e. construction or agricultural work.
If city-specific data on distribution of gross labor sectors is not available, the user can estimate the working population of the city in 3 sectors (service, industry, agriculture) using national-level World Bank data (e.g. "employment in industry, male (%)" and similar). Given the resting times in Table 2, and the proportion of working population in different sectors, loss of work time can be calculated for a given temperature. If local data on average hourly salaries for the different sectors are available, these losses in work time can be translated to monetary losses.

Finally, for "light work", note that A/C prevalence can play a role. If most office buildings are equipped with A/C, the user might want to reduce the loss of work time for the service sector by the same proportion as A/C prevalence.

Limitations and simplifications
===============================

Due to the simplifications presented above, the model presents a number of limitations which we summarize below:

Cooling capacity index: the CC index relies on empirical weights, derived from a limited number of case studies, which modulate the effect of key factors contributing to the cooling effect (Eq. 2). This weighting step comprises high uncertainties, as reviewed in Zardo et al. (2017). To characterize and reduce this uncertainty, users can test the sensitivity of the model to these parameters or conduct experimental studies that provide insights into the relative effect of shade, albedo, and evapotranspiration.

Effect of large parks and air mixing: two parameters capture the effect of large green spaces and the air mixing (d_cool and r). The value of these parameters is difficult to derive from the literature, as it varies with the vegetation properties, climate (effect of large green spaces) and wind patterns (air mixing). Similar to CC, users can characterize and reduce these uncertainties by testing the sensitivity of the model to these parameters and comparing spatial patterns of temperature estimated by the model with observed or modeled data (see Bartesaghi et al., 2018 and Deilami et al., 2018 for additional insights into such comparisons)
Valuation options: the valuation options currently supported by the model are related to the A/C energy consumption and the outside work productivity. For A/C energy consumption, users need to assess A/C prevalence, and reduce estimates accordingly (i.e. reduce energy consumption proportionally to actual use of A/C).

Valuation of the health effects of urban heat is currently not included in the model, despite their importance (McDonald et al. 2016). This is because these effects vary dramatically across cities and it is difficult to extrapolate current knowledge based predominantly in the global North (Campbell et al. 2018). Possible options to obtain health impact estimates include:
using global data from McMichael et al. (2004, WHO report), who use a linear relationship above a threshold temperature to estimate the annual attributable fraction of deaths due to hot days
for applications in the US, a methodology was developed based on national-scale relationships between mortality and temperature change: see Mc Donald et al. (in review)

Gasparrini et al. (2014) break down the increase in mortality attributable to heat for 384 cities in 13 countries. T_air output from the InVEST model could be used to determine the mortality fraction attributable to heat (first determine in which percentile T_air,i falls, then use Table S3 or Table S4 in the appendix).

Data needs
==========

* Workspace (required): Folder where model outputs will be written. Make sure that there is ample disk space, and write permissions are correct.

* Suffix (optional): Text string that will be appended to the end of output file names, as "_Suffix". Use a Suffix to differentiate model runs, for example by providing a short name for each scenario. If a Suffix is not provided, or changed between model runs, the tool will overwrite previous results.

* Land Cover Map (required): Raster of land use/land cover (LULC) for each pixel, where each unique integer represents a different land use/land cover class. All values in this raster MUST have corresponding entries in the Land Cover Biophysical Table. The model will use the resolution of this layer to resample all outputs. The resolution should be small enough to capture the effect of green areas in the landscape, although LULC categories can comprise a mix of vegetated and non-vegetated covers (e.g. "residential", which may have 30% canopy cover)

* Biophysical Table (required): A .csv (Comma Separated Value) table containing model information corresponding to each of the land use classes in the Land Cover Map. All LULC classes in the Land Cover raster MUST have corresponding values in this table. Each row is a land use/land cover class and columns must be named and defined as follows:

    * lucode: Required. Land use/land cover class code. LULC codes must match the 'value' column in the Land Cover Map raster and must be integer or floating point values, in consecutive order, and unique.
    * Shade: a value between 0 and 1, representing the proportion of tree cover (0 for no tree; 1 for full tree cover; with trees>2m).  Required if using the weighted factor approach to Cooling Coefficient calculations.
    * Kc: Required.  Crop coefficient, a value between 0 and 1 (see Allen et al. 1998).
    * Albedo: a value between 0 and 1, representing the proportion of solar radiation directly reflected by the LULC type. Required if using the weighted factor approach to Cooling Coefficient calculations.
    * Green_area: Required. A value of 0 or 1, 1 meaning that the LULC is counted as a green area (green areas >2ha have an additional cooling effect)
    * Building_intensity: A floating-point value between 0 and 1.  This is calculated by dividing the floor area by the land area, standardized between 0 and 1.  Required if using the weighted factor approach to Cooling Coefficient calculations.

* Ref. evapotranspiration: a raster representing reference evapotranspiration (in mm) for the period of interest (could be a specific date or monthly values can be used as a proxy)

* Areas of interest: vector delineating areas of interest (city boundaries or neighborhoods boundaries). Results will be aggregated within each shape contained in this vector

* Green Area Maximum Cooling Distance (:math:`d_{cool}`) : Distance (in m) over which large urban parks (> 2 ha) will have a cooling effect

* Reference Air Temperature (:math:`T_{ref}`): Rural reference temperature (where the urban heat island effect is not observed) for the period of interest. This could be nighttime or daytime temperature, for a specific date or an average over several days. The results will be given for the same period of interest).

* Magnitude of the UHI Effect (:math:`UHI_{max}`) : Magnitude of the urban heat island effect, in degC, i.e. the difference between the rural reference temperature and the maximum temperature observed in the city.

* Air Temperature Maximum Blending Distance: Search radius (in m) used in the moving average to account for air mixing (default value: 2000m)

* Cooling capacity calculation method: Either "Weighted Factors" or "Building Intensity".  The method selected here determines the predictor used for air temperature.  If "Weighted Factors" is selected, the Cooling Capacity calculations will use the weighted factors for shade, albedo and ETI as a predictor for daytime temperatures.  Alternatively, if "Building Intensity" is selected, building intensity will be used as a predictor for nighttime temperature instead of shade, albedo and ETI.

* Building Footprints Vector (Required if doing valuation): vector with built infrastructure footprints. The attribute table must contain a column 'Type', with integers referencing the building type (e.g. 1=residential, 2=office, etc.)

* Average relative humidity (0-100%) (Required if doing valuation): The average relative humidity (0-100%) over the time period of interest.

* Energy_consumption (Required if doing valuation): A .csv (Comma Separated Value) table containing information on energy consumption for each building type, in kWh/degC/:math:`m^2`. The table must contain the following columns:
    * "Type": building type defined in the vector above
    * "Consumption": energy consumption per building type, in kWh/degC/:math:`m^2`, where the :math:`m^2` refers to the area of the polygon footprint of the building in :math:`m^2`.  This consumption value must be adjusted for the average number of stories that structures of this type will have.
    * "RH" (optional): Average Relative Humidity [%] during the period of interest, which is used to calculate the wet bulb globe temperature for the work productivity module.
    * "cost" (optional): The cost per kWh (:math:`\$/kWh`) of electricity for each building type.  If this column is provided in the Energy Consumption table, the ``energy_sav`` field in the output vector ``buildings_with_stats.shp`` will be in monetary units rather than kWh.  This column is very likely to be the same for all building types.

* Cooling capacity: adjust shade weight.  The relative weight to apply to shade when calculating the cooling index. Default value: 0.6.

* Cooling capacity: adjust albedo weight. The relative weight to apply to albedo when calculating the cooling index.  Default value: 0.2.

* Cooling capacity: adjust evapotranspiration weight.  The relative weight to apply to ETI when calculating the cooling index.  Default value: 0.2.


Interpreting outputs
====================

The following is a short description of each of the outputs from the urban cooling model. Final results are found within the user defined Workspace specified for this model run. "Suffix" in the following file names refers to the optional user-defined Suffix input to the model.
Parameter log: Each time the model is run, a text (.txt) file will be created in the Workspace. The file will list the parameter values and output messages for that run and will be named according to the service, the date and time. When contacting NatCap about errors in a model run, please include the parameter log.

* hm_[Suffix].tif: The calculated Heat Mitigation (HM) Index.
* uhi_results_[Suffix].shp: A copy of the input vector with areas of interest with the following additional fields:
    * "avg_cc" - Average CC value (-)
    * "avg_tmp_v" - Average temperature value (degC)
    * "avg_tmp_an" - Average temperature anomaly (degC)
    * "avd_eng_cn" - (Optional) Avoided energy consumption ($)
    * "avg_wbgt_v" - (Optional) Average WBGT (degC)
    * "avg_ltls_v" - (Optional) Loss.light.work (%)
    * "avg_hvls_v" - (Optional) Loss.heavy.work (%)
    * "energy_sav" - (Optional) energy savings.  This is in units of kWh.  If the optional ``cost`` column is provided in the Energy Consumption CSV, units will instead be monetary units.
* buildings_with_stats[suffix].shp: A copy of the input vector with buildings with the following additional fields
    * "energy_sav" - Energy savings value ($)
    * "mean_T_air" - Average temperature value in building (degC)


In the intermediate folder, additional model outputs can be found:

* cc_[Suffix].tif: raster with values of the cooling capacity (CC)
* T_air_[Suffix].tif: raster with estimated temperature values
* T_air_nomix_[Suffix].tif: raster with estimated temperature values prior to air mixing (i.e. before applying the moving average algorithm)
* eti_[Suffix].tif: raster with values of actual evapotranspiration (reference evapotranspiration times crop coefficient Kc)
* wbgt_[Suffix].tif: The calculated Wet Bulb Globe Temperature (WBGT)
* reprojected_aoi_[Suffix].shp: The user-defined Area of Interest, reprojected to the Spatial Reference of the LULC.
* reprojected_buildings_[Suffix].shp: The user-defined buildings vector, reprojected to the Spatial Reference of the LULC.

Appendix: Data sources and guidance for parameter selection
===========================================================

The following table summarizes possible data sources for inputs specific to the urban cooling model. Additional information on common InVEST inputs (e.g. LULC, evapotranspiration) can be found in the annual water yield model documentation.

.. csv-table::
  :file: ucm_appendix_table.csv
  :header-rows: 1
  :name: Data sources for parameter selection

FAQs
====
* What is the output resolution?

    Model outputs are of two types: rasters and vectors. Rasters will have the same resolution as the LULC input (all other raster inputs will be resampled to the same resolution).

* Why aren't the health impacts calculated by the model?

    Effects of heat on human health vary dramatically across cities and it is difficult to develop a generic model within InVEST. See the point Valuation of the health effects in the Model limitations section for additional details and pathways to assess the health impacts of urban heat mitigation.


References
==========

Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop evapotranspiration - Guidelines for computing crop water requirements - FAO Irrigation and drainage paper 56. FAO, Rome, Italy.

Bartesaghi, C., Osmond, P., & Peters, A. (2018). Evaluating the cooling effects of green infrastructure : A systematic review of methods , indicators and data sources. Solar Energy, 166(February), 486-508. https://doi.org/10.1016/j.solener.2018.03.008

Campbell, S., Remenyi, T. A., White, C. J., & Johnston, F. H. (2018). Heatwave and health impact research: A global review. Health & Place, 53, 210-218. https://doi.org/https://doi.org/10.1016/j.healthplace.2018.08.017

Deilami, K., Kamruzzaman, M., & Liu, Y. (2018). Urban heat island effect: A systematic review of spatio-temporal factors, data, methods, and mitigation measures. International Journal of Applied Earth Observation and Geoinformation, 67, 30-42. https://doi.org/https://doi.org/10.1016/j.jag.2017.12.009

Kjellstrom, T., Holmer, I., & Lemke, B. (2009). Workplace heat stress, health and productivity - an increasing challenge for low and middle-income countries during climate change. Global Health Action, 2, 10.3402/gha.v2i0.2047. https://doi.org/10.3402/gha.v2i0.2047

Kunapo, J., Fletcher, T. D., Ladson, A. R., Cunningham, L., & Burns, M. J. (2018). A spatially explicit framework for climate adaptation. Urban Water Journal, 15(2), 159-166. https://doi.org/10.1080/1573062X.2018.1424216

McDonald, R. I., Kroeger, T., Boucher, T., Wang, L., & Salem, R. (2016). Planting Healthy Air: A global analysis of the role of urban trees in addressing particulate matter pollution and extreme heat. Arlington, VA.

Phelan, P. E., Kaloush, K., Miner, M., Golden, J., Phelan, B., Iii, H. S., & Taylor, R. A. (2015). Urban Heat Island : Mechanisms , Implications , and Possible Remedies. Annual Review of Environment and Resources, 285-309. https://doi.org/10.1146/annurev-environ-102014-021155

Santamouris, M., Cartalis, C., Synnefa, A., & Kolokotsa, D. (2015). On the impact of urban heat island and global warming on the power demand and electricity consumption of buildings - A review. Energy & Buildings, 98, 119-124. https://doi.org/10.1016/j.enbuild.2014.09.052

Stewart, I. D., & Oke, T. R. (2012). Local climate zones for urban temperature studies. American Meteorological Society. https://doi.org/10.1175/BAMS-D-11-00019.1

Zardo, L., Geneletti, D., Prez-soba, M., & Eupen, M. Van. (2017). Estimating the cooling capacity of green infrastructures to support urban planning. Ecosystem Services, 26, 225-235. https://doi.org/10.1016/j.ecoser.2017.06.016
