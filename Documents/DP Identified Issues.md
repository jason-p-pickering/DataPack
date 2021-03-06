## Issues and Fixes to the Data Pack

updated: Feb 20

Here is a running list of issues that affect the Data Pack for SI and EA advisors to be aware of

1. Wrong columns referenced
    - Issue: Due some updated in the template, a few formulas point to the wrong reference columns
    - Affected Tab: SNU Targets for EA
    - Fix:
        1. Change the formulas in the 3 cells identified below, updating the column letter in bold (note that [LastColumn] will be the last row number in your Data Pack)
            * O7 =INDEX('Target Calculation'!$**BO**$5:$**BO**$[LastRow],MATCH(Tsnulist, snu,0))
            * Q7 =INDEX('Target Calculation'!$**BC**$5:$**BC**$[LastRow],MATCH(Tsnulist, snu,0))
            * U7 =INDEX('HTC Target Calculation'!**O**$5:**O**$[LastRow],MATCH(Tsnulist, snu,0))
        2. For each affected column (O, Q, U), copy the new formula down to all rows
2. KP_MAT data missing
    - Issue: The KP_MAT column in the IM distribution was missing data (only affected 5 OUs - Central Asia Region, India, Kenya, Tanzania, and Vietnam)
    - Affected Tab - Allocation by IM
    - Fix:
        1. SI advisors were identified regarding this issue, and provided either (a) the rows in column X to add KP_MAT % to if <5 rows affected, or (b) were issued new Data Packs and can be found on PEPFAR.net
3. VMMC included in EA HTC calculation
    - Issue: For the purposes of EA, VMMC and PMTCT test needs to be removed from the HTC to ensure we are not double counting those expenses in our Unit Expenditures. VMMC was mistakenly included in HTC total.
    - Affected Tab: SNU Targets for EA
    - Fix:
        1. Navigate to the HTC Target Calculation tab
        2. Unhide columns M through P
        3. Insert a new column after P
        4. In cell Q4, add the header title Total EA HTC
        5. Add a formula to columns M-P in column Q
            * Q7 = SUM(M7:P7)
        6. Copy this new formula down to all the rows in this column
        7. Navigate to the SNU Targets for EA tab
        8. Replace the formula in S7, HTC_TST(excluding PMTCT & VMMC), with the formula below
            * S7 = INDEX(**'HTC Target Calculation'!Q$5:Q$[LastRow]**,MATCH(Tsnulist, htc_snu,0))
        9. Copy this formula down to the rest of the rows in the column
        
        NOTE: A change was made in step h. The original fix (...$Q$7:$Q$[LastRow]...) was causing errors.
        NOTE 2: A second change was made in step h. The revised fix (...Q$7:Q$[LastRow]...) was causing errors.

4. TX_CURR Patient Year calculation
    - Issue: The current formula to calculate the patient year uses PMTCT_EID as a proxy for TX_CURR <1 (which is used to get TX_CURR 1-15 from the TX_CUR <15 calcuated in the Data Pack). Since PMTCT_EID over estimates those on treatment since it includes negative tests as well, so TX_NEW <1 should be used instead (as is used for the FY18 calculation).
    - Affected Tab: SNU Targets for EA
    - Fix:
        1. Change the formula in cell F7 to point to the FY17 TX_NEW <1 Target located in the DATIM Indicator Table
            * F7 =INDEX(**tx_new_u1_T**,MATCH(Tsnulist,snulist,0))
        2. Copy the formula down to all rows in column F, TX_CURR (<1) [PMTCT_EID]
        3. Rename the header to TX_CURR (<1) [**TX_NEW <1**]
5. Wrong SNU reference
  - Issue: The current formula indexes the SNU list from the main Target Calcuations tab, rather than the HTC Target Calcuation tabs. This could reference the wrong cells if the SNU lists are sorted in different orders
  - Affected Tab: SNU Targets for EA
  - Fix:
        1. Replace MATCH(Tsnulist,**snu**,0)" with MATCH(Tsnulist,**snu_htc**,0) in columns S, T, U, and V
            * S7 = INDEX(T_htc_need,MATCH(Tsnulist, **snu_htc**,0))
6. Incorrect indicator reference
  - Issue: The forumula for the OVC target on the PBAC tab has an extra letter included that is throwing off the reference, causing no data to show up in column AG.
  - Affected Tab: PBAC IM Targets
  - Fix:
      1. Remove the mistyped "A" in "AP_indtype" so it is just "P_indtype" in AG7
        * AG7 =  SUMIFS(D_ovc_serv_fy18,D_priority,P_mech,D_type,**P_indtype**,D_mech,">1")
      2. Copy the formula from AG7 down to the AG13
      3. Remove the "A" in AP_indtype so it is just P_indtype in AG15
        * AG15 = =SUMIFS(D_ovc_serv_fy18,D_mech,P_mech,D_type,**P_indtype**)
      4. Copy the formula in AG15 down to the last row 

7. 2016 PLHIV points to wrong reference 
  - Issue: The formula for 2016 PLHIV in the target setting tab points to the DATIM Indicator tab, when it should point to the Assumptions tab. If the country team makes changes to their 2016 PLHIV numbers, they won't be reflected in the target setting tab.
  - Affected Tab: Target Calculation
  - Fix:
      1. In cell F7, replace =INDEX(plhiv,MATCH(snu,snulist,0)) with =INDEX(M_plhiv_fy16,MATCH(snu,Msnulist,0))
      2. Copy the formula from F7 down to the last row.
      
8. Pediatric HTC is calculated on all treatment under five and doesn't exclude EID (under 1)
 - Issue: The formula for total pediatric positives to identify in the HTC Target Calculation tab currently pulls all pediatric positives, instead of excluding those under one who are found through EID and do not need to be found through the HTC testing program. 
  - Affected Tab: HTC Target Calculation
  - Fix:
      1. You must create a named reference for T_eid_treat. This is done in the Excel Name Manager
         1. Under the excel ribbon "Formulas" click on name manager. 
         2. Create a new named range called "T_eid_treat" and set it to reference ='Target Calculation'!$BQ$5:$BQ$[Last Row] (which is               FY18 Target TX_NEW (under 1)
      2. In the HTC Target Calculation tab, in cell F7, replace =IFERROR(INDEX(T_ped_treat,MATCH(snu_htc,snu,0))/D7,0)
      with =IFERROR(IF((INDEX(T_ped_treat,MATCH(snu_htc,snu,0))-INDEX(T_eid_treat,MATCH(snu_htc,snu,0)))<0,0,         (INDEX(T_ped_treat,MATCH(snu_htc,snu,0))-INDEX(T_eid_treat,MATCH(snu_htc,snu,0))))/D7,0)
      3. Copy the formula from F7 down to the last row. 

9. PEPFARs coverage of Net New is misapplied
 - Issue: The formula for calulating Net New takes into consideration PEPFARs coverage of net new. This formula misapplies PEPFAR coverage in SNUs where coverage is less than 100%.
  - Affected Tab: Target Calculation
  - Fix:
      1. In cell AD7, replace `=IFERROR(IF(AC7*G7*AB7-IF(N7>AA7,N7,AA7)<0,0,AC7*G7*AB7-IF(N7>AA7,N7,AA7)),0)` with `=IFERROR(IF(AC7*(G7*AB7-IF(N7>AA7,N7,AA7))<0,0,AC7*(G7*AB7-IF(N7>AA7,N7,AA7))),0)`
      2. Copy the formula from AD7 down to the last row.

10. Wrong prioritization reference in Allocation by IM tab 
  - Issue: The formula for SNU prioritization in the Allocation by IM tab uses the original prioritization from DATIM. If there is a change made to the prioritization in the Assumptions tab, it will not be reflected here
  - Affected Tab: Allocation by IM
  - Fix:
      1. In cell D7, replace =IFERROR(INDEX(**priority_snu**,MATCH(Dsnulist,snulist,0)),"NOT DEFINED") with =IFERROR(INDEX(**M_priority_snu**,MATCH(Dsnulist,snulist,0)),"NOT DEFINED")
      2. Copy the formula from D7 down to the last row.

11. Potential double-counting of HTC 
  - Issue: Some of the named ranges are starting from cell 7 when they should start at cell 5. This is causing random errors including 
  REF errors and double counting of certain HTC numbers.
  - Affected Tab: SNU Targets for EA
  - Fix:
      1. In cells S7, T7, U7, and V7, replace ('HTC Target Calculation'!..**$7**:..$[Last Row]) with ('HTC Target Calculation'!..**$5**:..$[Last Row]) 
      2. This will cause errors which will be fixed by step c. 
      3. You must change some named references. This is done in the Excel Name Manager.
         1. Under the excel ribbon "Formulas" click on name manager. 
         2. Change the following named ranges:
            1. htc_snu: From ='HTC Target Calculation'!$C$7:$C$[Last Row] to ='HTC Target Calculation'!$C$5:$C$[Last Row]
            2. snu_htc: From ='HTC Target Calculation'!$C$7:$C$[Last Row] to ='HTC Target Calculation'!$C$5:$C$[Last Row]
            3. Tsnulist: From ='SNU Targets for EA'!$C$7:$C$[Last Row] to ='SNU Targets for EA'!$C$5:$C$[Last Row]

12. PBAC IM Targets PMTCT_EID points to TX_under1
  - Issue: The forumula for the PMTCT_EID points to TX_under1 and it should point to PMTCT_EID
  - Affected Tab: PBAC IM Targets
  - Fix:
      1. Select Column N and O, and search and replace.
      2. For the whole of those two columns, replace **D_tx_curr_u1_fy18** with **D_pmtct_eid_fy18**
