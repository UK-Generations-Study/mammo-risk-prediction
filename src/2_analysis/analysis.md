# Mammography AI Breast Cancer Risk Stratification in a UK Population


<p><a href="https://github.com/UK-Generations-Study/mammo-risk-prediction/blob/main/README.md">← Back to repository README</a></p>

## Analysis

### Figure 1

Violin plots of risk factors and Mirai

![](analysis_files/figure-commonmark/unnamed-chunk-11-1.png)

### Table 1

Descriptive table of the study population for the variables included in
the GAIL model

| **Characteristic** | **Controls, N = 369** | **Cases, N = 241** |
|:---|:--:|:--:|
| **Age at mammogram (years), Median (IQR)** | 63.6 (56.3-68.7) | 61.1 (54.9-65.9) |
| **Mammography device used** |  |  |
| Lorad Selenia | 228 (62%) | 168 (70%) |
| Selenia Dimensions | 141 (38%) | 73 (30%) |
| **Race/ethnicity** |  |  |
| White | 365 (99%) | 238 (99%) |
| Non-white | 4 (1.1%) | 3 (1.2%) |
| **Age at menarche (years), Median (IQR)** | 13.0 (11.0-14.0) | 12.0 (11.0-13.0) |
| Unknown | 40 | 27 |
| **Age at first live birth (years)** |  |  |
| 24-25 | 65 (18%) | 38 (16%) |
| 26-29 | 83 (23%) | 45 (19%) |
| 30+ | 94 (26%) | 84 (35%) |
| \<24 | 78 (21%) | 42 (18%) |
| Nulliparous | 45 (12%) | 30 (13%) |
| Unknown | 4 | 2 |
| **No. benign breast biopsies** |  |  |
| 0 | 359 (97%) | 225 (93%) |
| 1+ | 10 (2.7%) | 16 (6.6%) |
| **No. 1st-degree relatives with breast cancer** |  |  |
| 0 | 314 (85%) | 186 (77%) |
| 1+ | 55 (15%) | 55 (23%) |
| **Mirai 5-year absolute risk (%), Median (IQR)** | 1.6 (1.3-2.2) | 2.5 (2.0-5.3) |
| **Gail 5-year absolute risk (%), Median (IQR)** | 1.7 (1.4-2.0) | 1.7 (1.4-2.2) |
| **Percent breast density (%), Median (IQR)** | 12.4 (6.9-20.8) | 16.1 (8.8-23.9) |
| Unknown | 226 | 147 |
| **Age at BC diagnosis (years), Median (IQR)** | \- | 64.1 (57.9-69.1) |
| **Time from mammogram to BC diagnosis (years), Median (IQR)** | \- | 2.9 (2.1-3.1) |
| **Cancer type** |  |  |
| Invasive | \- | 189 (78%) |
| DCIS | \- | 52 (22%) |
| **ER status** |  |  |
| Positive | \- | 138 (80%) |
| Negative | \- | 34 (20%) |
| Unknown | 0 | 69 |

### Table 2

| Model | Cases/Controls | Mirai | Gail | PD | AUC (95% CI) | Calibration Slope (95% CI) |
|:---|:---|:---|:---|:---|:---|:---|
| Model 1 | 241/369 | 2.84 (2.39, 3.12) | \- | \- | 0.74 (0.72, 0.76) | 1.75 (1.31, 2.24) |
| Model 2 | 241/369 | \- | 1.30 (1.16, 1.45) | \- | 0.56 (0.54, 0.59) | 1.24 (0.51, 2.01) |
| Model 4 | 241/369 | 2.81 (2.39, 3.07) | 1.22 (1.15, 1.38) | \- | 0.74 (0.72, 0.77) | \- |
| Model 1 | 94/143 | 2.20 (1.68, 2.86) | \- | \- | 0.68 (0.60, 0.72) | 1.19 (0.22, 2.37) |
| Model 2 | 94/143 | \- | 1.27 (1.05, 1.62) | \- | 0.56 (0.46, 0.63) | \- |
| Model 3 | 94/143 | \- | \- | 1.12 (1.00, 1.32) | 0.56 (0.49, 0.62) | \- |
| Model 4 | 94/143 | 2.22 (1.69, 2.86) | 1.29 (1.07, 1.72) | \- | 0.66 (0.60, 0.72) | \- |
| Model 5 | 94/143 | 2.16 (1.69, 2.65) | \- | 1.04 (0.91, 1.21) | 0.67 (0.56, 0.71) | \- |
| Model 6 | 94/143 | \- | 1.26 (1.04, 1.62) | 1.11 (0.99, 1.27) | 0.56 (0.47, 0.64) | \- |
| Model 7 | 94/143 | 2.20 (1.71, 2.71) | 1.28 (1.05, 1.71) | 1.02 (0.91, 1.15) | 0.65 (0.60, 0.71) | \- |

## Supplementary Material

### Supplementary Table 1

Correlations of the MIRAI score with variables included in the GAIL
model as well as mammographic density

<div id="xmsxtibjkv" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#xmsxtibjkv table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#xmsxtibjkv thead, #xmsxtibjkv tbody, #xmsxtibjkv tfoot, #xmsxtibjkv tr, #xmsxtibjkv td, #xmsxtibjkv th {
  border-style: none;
}
&#10;#xmsxtibjkv p {
  margin: 0;
  padding: 0;
}
&#10;#xmsxtibjkv .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#xmsxtibjkv .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#xmsxtibjkv .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#xmsxtibjkv .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#xmsxtibjkv .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#xmsxtibjkv .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#xmsxtibjkv .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#xmsxtibjkv .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#xmsxtibjkv .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#xmsxtibjkv .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#xmsxtibjkv .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#xmsxtibjkv .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#xmsxtibjkv .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#xmsxtibjkv .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#xmsxtibjkv .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xmsxtibjkv .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#xmsxtibjkv .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#xmsxtibjkv .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#xmsxtibjkv .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xmsxtibjkv .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#xmsxtibjkv .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xmsxtibjkv .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#xmsxtibjkv .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xmsxtibjkv .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#xmsxtibjkv .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xmsxtibjkv .gt_left {
  text-align: left;
}
&#10;#xmsxtibjkv .gt_center {
  text-align: center;
}
&#10;#xmsxtibjkv .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#xmsxtibjkv .gt_font_normal {
  font-weight: normal;
}
&#10;#xmsxtibjkv .gt_font_bold {
  font-weight: bold;
}
&#10;#xmsxtibjkv .gt_font_italic {
  font-style: italic;
}
&#10;#xmsxtibjkv .gt_super {
  font-size: 65%;
}
&#10;#xmsxtibjkv .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#xmsxtibjkv .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#xmsxtibjkv .gt_indent_1 {
  text-indent: 5px;
}
&#10;#xmsxtibjkv .gt_indent_2 {
  text-indent: 10px;
}
&#10;#xmsxtibjkv .gt_indent_3 {
  text-indent: 15px;
}
&#10;#xmsxtibjkv .gt_indent_4 {
  text-indent: 20px;
}
&#10;#xmsxtibjkv .gt_indent_5 {
  text-indent: 25px;
}
&#10;#xmsxtibjkv .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#xmsxtibjkv div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>

<table class="gt_table" data-quarto-postprocess="true"
data-quarto-disable-processing="false" data-quarto-bootstrap="false">
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
</colgroup>
<thead>
<tr class="gt_col_headings gt_spanner_row">
<th rowspan="2" id="variable"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th" scope="col"><strong>Risk
Factor</strong></th>
<th colspan="2" id="a*Univariable*"
class="gt_center gt_columns_top_border gt_column_spanner_outer"
data-quarto-table-cell-role="th" scope="colgroup"><div
class="gt_column_spanner">
<em>Univariable</em>
</div></th>
<th colspan="2" id="a*Multivariable*"
class="gt_center gt_columns_top_border gt_column_spanner_outer"
data-quarto-table-cell-role="th" scope="colgroup"><div
class="gt_column_spanner">
<em>Multivariable</em>
</div></th>
</tr>
<tr class="gt_col_headings">
<th id="beta_1" class="gt_col_heading gt_columns_bottom_border gt_right"
data-quarto-table-cell-role="th" scope="col"><strong>Beta (95%
CI)</strong></th>
<th id="p_value_1"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th" scope="col"><strong>P
Value</strong></th>
<th id="beta_2" class="gt_col_heading gt_columns_bottom_border gt_right"
data-quarto-table-cell-role="th" scope="col"><strong>Beta (95%
CI)</strong></th>
<th id="p_value_2"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th" scope="col"><strong>P
Value</strong></th>
</tr>
</thead>
<tbody class="gt_table_body">
<tr>
<td class="gt_row gt_center" headers="variable">Age at mammogram
(years)</td>
<td class="gt_row gt_right" headers="beta_1">0.01 (0.00, 0.02)</td>
<td class="gt_row gt_left" headers="p_value_1">0.008</td>
<td class="gt_row gt_right" headers="beta_2">0.01 (0.00, 0.02)</td>
<td class="gt_row gt_left" headers="p_value_2">0.007</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">No. breast biopsies</td>
<td class="gt_row gt_right" headers="beta_1">-0.00 (-0.32, 0.31)</td>
<td class="gt_row gt_left" headers="p_value_1">0.977</td>
<td class="gt_row gt_right" headers="beta_2">-0.08 (-0.39, 0.23)</td>
<td class="gt_row gt_left" headers="p_value_2">0.611</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">Age at menarche
(years)</td>
<td class="gt_row gt_right" headers="beta_1">0.01 (-0.03, 0.05)</td>
<td class="gt_row gt_left" headers="p_value_1">0.643</td>
<td class="gt_row gt_right" headers="beta_2">0.00 (-0.03, 0.04)</td>
<td class="gt_row gt_left" headers="p_value_2">0.884</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">Parity</td>
<td class="gt_row gt_right" headers="beta_1">0.12 (-0.03, 0.28)</td>
<td class="gt_row gt_left" headers="p_value_1">0.129</td>
<td class="gt_row gt_right" headers="beta_2">0.25 (-0.07, 0.58)</td>
<td class="gt_row gt_left" headers="p_value_2">0.125</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">Age at first birth
(years)</td>
<td class="gt_row gt_right" headers="beta_1">-0.00 (-0.01, 0.01)</td>
<td class="gt_row gt_left" headers="p_value_1">0.512</td>
<td class="gt_row gt_right" headers="beta_2">-0.01 (-0.02, 0.01)</td>
<td class="gt_row gt_left" headers="p_value_2">0.314</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">Family history of
BC</td>
<td class="gt_row gt_right" headers="beta_1">0.13 (-0.02, 0.27)</td>
<td class="gt_row gt_left" headers="p_value_1">0.083</td>
<td class="gt_row gt_right" headers="beta_2">0.12 (-0.02, 0.26)</td>
<td class="gt_row gt_left" headers="p_value_2">0.096</td>
</tr>
<tr>
<td class="gt_row gt_center" headers="variable">Percent breast
density</td>
<td class="gt_row gt_right" headers="beta_1">0.01 (0.01, 0.02)</td>
<td class="gt_row gt_left" headers="p_value_1">&lt;0.001</td>
<td class="gt_row gt_right" headers="beta_2">0.02 (0.01, 0.02)</td>
<td class="gt_row gt_left" headers="p_value_2">&lt;0.001</td>
</tr>
</tbody>
</table>

</div>

### Supplementary Table 2

<div id="jpjwaqafye" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#jpjwaqafye table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#jpjwaqafye thead, #jpjwaqafye tbody, #jpjwaqafye tfoot, #jpjwaqafye tr, #jpjwaqafye td, #jpjwaqafye th {
  border-style: none;
}
&#10;#jpjwaqafye p {
  margin: 0;
  padding: 0;
}
&#10;#jpjwaqafye .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#jpjwaqafye .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#jpjwaqafye .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#jpjwaqafye .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#jpjwaqafye .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#jpjwaqafye .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#jpjwaqafye .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#jpjwaqafye .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#jpjwaqafye .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#jpjwaqafye .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#jpjwaqafye .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#jpjwaqafye .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#jpjwaqafye .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#jpjwaqafye .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#jpjwaqafye .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#jpjwaqafye .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#jpjwaqafye .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#jpjwaqafye .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#jpjwaqafye .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#jpjwaqafye .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#jpjwaqafye .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#jpjwaqafye .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#jpjwaqafye .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#jpjwaqafye .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#jpjwaqafye .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#jpjwaqafye .gt_left {
  text-align: left;
}
&#10;#jpjwaqafye .gt_center {
  text-align: center;
}
&#10;#jpjwaqafye .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#jpjwaqafye .gt_font_normal {
  font-weight: normal;
}
&#10;#jpjwaqafye .gt_font_bold {
  font-weight: bold;
}
&#10;#jpjwaqafye .gt_font_italic {
  font-style: italic;
}
&#10;#jpjwaqafye .gt_super {
  font-size: 65%;
}
&#10;#jpjwaqafye .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#jpjwaqafye .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#jpjwaqafye .gt_indent_1 {
  text-indent: 5px;
}
&#10;#jpjwaqafye .gt_indent_2 {
  text-indent: 10px;
}
&#10;#jpjwaqafye .gt_indent_3 {
  text-indent: 15px;
}
&#10;#jpjwaqafye .gt_indent_4 {
  text-indent: 20px;
}
&#10;#jpjwaqafye .gt_indent_5 {
  text-indent: 25px;
}
&#10;#jpjwaqafye .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#jpjwaqafye div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>

<table class="gt_table" data-quarto-postprocess="true"
data-quarto-disable-processing="false" data-quarto-bootstrap="false">
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr class="gt_col_headings">
<th id="label" class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th"
scope="col"><strong>Characteristic</strong></th>
<th id="n" class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th" scope="col"><strong>N</strong></th>
<th id="stat_1"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th" scope="col"><strong>Controls, N =
369</strong><span class="gt_footnote_marks"
style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></th>
<th id="stat_2"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th" scope="col"><strong>Cases, N =
241</strong><span class="gt_footnote_marks"
style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></th>
</tr>
</thead>
<tbody class="gt_table_body">
<tr>
<td class="gt_row gt_left" headers="label"
style="font-weight: bold">Time from mammogram to BC diagnosis
(years)</td>
<td class="gt_row gt_center" headers="n">610</td>
<td class="gt_row gt_center" headers="stat_1"><br />
</td>
<td class="gt_row gt_center" headers="stat_2"><br />
</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="label">    &lt;=5 years</td>
<td class="gt_row gt_center" headers="n"><br />
</td>
<td class="gt_row gt_center" headers="stat_1">8 (2.2%)</td>
<td class="gt_row gt_center" headers="stat_2">221 (92%)</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="label">    &gt;5 years</td>
<td class="gt_row gt_center" headers="n"><br />
</td>
<td class="gt_row gt_center" headers="stat_1">5 (1.4%)</td>
<td class="gt_row gt_center" headers="stat_2">20 (8.3%)</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="label">    Control</td>
<td class="gt_row gt_center" headers="n"><br />
</td>
<td class="gt_row gt_center" headers="stat_1">356 (96%)</td>
<td class="gt_row gt_center" headers="stat_2">0 (0%)</td>
</tr>
</tbody><tfoot>
<tr class="gt_footnotes">
<td colspan="4" class="gt_footnote"><span class="gt_footnote_marks"
style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span>
n (%)</td>
</tr>
</tfoot>
&#10;</table>

</div>

### Supplementary Table 3

<div id="wyixklbzrl" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#wyixklbzrl table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#wyixklbzrl thead, #wyixklbzrl tbody, #wyixklbzrl tfoot, #wyixklbzrl tr, #wyixklbzrl td, #wyixklbzrl th {
  border-style: none;
}
&#10;#wyixklbzrl p {
  margin: 0;
  padding: 0;
}
&#10;#wyixklbzrl .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#wyixklbzrl .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#wyixklbzrl .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#wyixklbzrl .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#wyixklbzrl .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#wyixklbzrl .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#wyixklbzrl .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#wyixklbzrl .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#wyixklbzrl .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#wyixklbzrl .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#wyixklbzrl .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#wyixklbzrl .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#wyixklbzrl .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#wyixklbzrl .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#wyixklbzrl .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wyixklbzrl .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#wyixklbzrl .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#wyixklbzrl .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#wyixklbzrl .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wyixklbzrl .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#wyixklbzrl .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wyixklbzrl .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#wyixklbzrl .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wyixklbzrl .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#wyixklbzrl .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#wyixklbzrl .gt_left {
  text-align: left;
}
&#10;#wyixklbzrl .gt_center {
  text-align: center;
}
&#10;#wyixklbzrl .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#wyixklbzrl .gt_font_normal {
  font-weight: normal;
}
&#10;#wyixklbzrl .gt_font_bold {
  font-weight: bold;
}
&#10;#wyixklbzrl .gt_font_italic {
  font-style: italic;
}
&#10;#wyixklbzrl .gt_super {
  font-size: 65%;
}
&#10;#wyixklbzrl .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#wyixklbzrl .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#wyixklbzrl .gt_indent_1 {
  text-indent: 5px;
}
&#10;#wyixklbzrl .gt_indent_2 {
  text-indent: 10px;
}
&#10;#wyixklbzrl .gt_indent_3 {
  text-indent: 15px;
}
&#10;#wyixklbzrl .gt_indent_4 {
  text-indent: 20px;
}
&#10;#wyixklbzrl .gt_indent_5 {
  text-indent: 25px;
}
&#10;#wyixklbzrl .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#wyixklbzrl div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>

| years | GAIL              | Mirai             |
|-------|-------------------|-------------------|
| 1     | 0.58 (0.53, 0.62) | 0.76 (0.72, 0.80) |
| 2     | 0.57 (0.53, 0.62) | 0.76 (0.72, 0.80) |
| 3     | 0.57 (0.52, 0.62) | 0.76 (0.72, 0.79) |
| 4     | 0.57 (0.52, 0.61) | 0.75 (0.71, 0.79) |
| 5     | 0.57 (0.52, 0.61) | 0.75 (0.71, 0.79) |

</div>
