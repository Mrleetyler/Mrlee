-- ## Port KPIs ## --
SELECT C.*, 
       CASE WHEN C.AVAIL_MAN_HRS = 0 THEN NULL ELSE ROUND ( C.LOADED_MAN_HRS / C.AVAIL_MAN_HRS * 100,2 ) END AS CAP_ACHIEVED , 
       CASE WHEN C.LOADED_MAN_HRS = 0 THEN NULL ELSE ROUND ( C.MAN_HRS_ACHIEVED / C.LOADED_MAN_HRS * 100,2 ) END AS ACHIEVED_VS_LOADED, 
       CASE WHEN C.AVAIL_MAN_HRS = 0 THEN NULL ELSE ROUND ( C.MAN_HRS_ACHIEVED / C.AVAIL_MAN_HRS * 100,2 ) END AS ACHIEVED_VS_AVAIL 
  FROM ( SELECT b.actual_start_date , 
                NVL ( b.location,'TOTAL' ) AS Location , 
                SUM ( b.avail_man_hrs ) AS AVAIL_MAN_HRS , 
                SUM ( b.loaded_man_hrs ) AS LOADED_MAN_HRS , 
                SUM ( b.man_hrs_achieved ) AS MAN_HRS_ACHIEVED, 
                SUM ( b.man_hrs_lost ) AS MAN_HRS_LOST , 
                SUM ( b.deferred_tc ) AS DEFERRED_TC 
           FROM ( SELECT A.ACTUAL_START_DATE, 
                         A.LOCATION , 
                         CASE WHEN location = 'BNE' THEN CASE WHEN TO_CHAR ( actual_start_date,'D' ) IN ( 3,5 ) 
                         THEN 70 ELSE 115 END WHEN location = 'BNE VANZ' 
                         THEN CASE WHEN TO_CHAR ( actual_start_date,'D' ) IN ( 3,5 ) THEN 75 ELSE 0 END 
                         WHEN LOCATION = 'SYD' THEN 30 WHEN LOCATION = 'PER' THEN 25 
                         WHEN LOCATION = 'ADL' THEN 5 WHEN LOCATION IN ( 'CBR','OOL' ) THEN 0 
                         WHEN LOCATION = 'MEL' 
                         THEN CASE WHEN MOD( TO_DATE(TO_CHAR ( actual_start_date,'DD/MM/YYYY'), 'DD/MM/YYYY') - TO_DATE('20/05/2014','DD/MM/YYYY') , 8) IN ( 0, 1, 2, 3 ) 
                         THEN 170 
                         WHEN MOD( TO_DATE(TO_CHAR ( actual_start_date,'DD/MM/YYYY'), 'DD/MM/YYYY') - TO_DATE('20/05/2014','DD/MM/YYYY') , 8) IN ( 4, 5, 6, 7 ) 
                         THEN 150 END ELSE 1 END AS AVAIL_MAN_HRS , 
                         NVL ( A.ACHIEVED_MAN_HRS,0 ) + NVL ( A.LOST_MAN_HRS,0 ) AS LOADED_MAN_HRS , 
                         NVL ( A.ACHIEVED_MAN_HRS,0 ) AS MAN_HRS_ACHIEVED, 
                         NVL ( A.LOST_MAN_HRS,0 ) AS MAN_HRS_LOST , 
                         NVL ( A.LOST_COUNT_TC,0 ) AS DEFERRED_TC 
                    FROM ( SELECT * 
                             FROM ( SELECT NVL ( ACTUAL_START_DATE ,:start_date ) AS ACTUAL_START_DATE, 
                                           LOCATION , 
                                           STATUS , 
                                           SUM ( TC_HOURS ) AS Loaded_Hrs , 
                                           COUNT ( TC_HOURS ) AS COUNT_TC 
                                      FROM ( SELECT WOL.actual_start_date, 
                                                    
                                                    wol.location , 
                                                    wtc.status , 
                                                    WTC.task_card , 
                                                    CASE WHEN SUM ( WTCI.man_hours ) = 0 THEN 1 ELSE SUM ( WTCI.man_hours ) END AS TC_HOURS 
                                               FROM ( SELECT WO.WO, 
                                                             
                                                             CASE WHEN WO.ac LIKE 'ZK%' THEN 'BNE VANZ' ELSE LM.LOCATION END AS LOCATION, 
                                                             WO.actual_start_date 
                                                        FROM LOCATION_MASTER LM LEFT OUTER JOIN wo ON LM.location = WO.location 
                                                         AND wo.actual_start_date = :start_date
                                                         AND wo.expenditure != 'COMWIFI' 
                                                       WHERE LM.location IN ( 'MEL','BNE','BNE VANZ','SYD','PER','ADL','OOL','CBR') ) WOL LEFT OUTER JOIN WO_TASK_CARD WTC ON WOL.WO = WTC.WO LEFT OUTER JOIN wo_task_card_item wtci ON WTC.WO = wtci.wo 
                                 AND WTC.task_card = WTCI.task_card 
                                 AND WTC.PN = WTCI.task_card_pn 
                                 AND WTC.PN_SN = WTCI.task_card_pn_sn 
                               GROUP BY WOL.actual_start_date, 
                                     WOL.location , 
                                     WTC.task_card , 
                                     wtc.status ) WO_TC_HOURS 
       GROUP BY ACTUAL_START_DATE, 
             LOCATION , 
             STATUS 
       ORDER BY LOCATION ) PIVOT ( SUM ( LOADED_HRS ) AS MAN_HRS, 
                                    SUM ( COUNT_TC ) AS COUNT_TC FOR STATUS IN ( 'CLOSED' AS ACHIEVED,'CANCEL' AS LOST ) ) 
ORDER BY LOCATION ) A ) b 
GROUP BY grouping sets ( b.actual_start_date, 
                                 b.location ) 
ORDER BY 2 ) C;

select wo.schedule_start_date, location, sum(wtci.man_hours), trunc(wo.schedule_completion_date) - trunc(wo.schedule_completion_date) as Days from wo
left outer join wo_task_card wtc on wtc.wo = wo.wo
left outer join wo_task_card_item wtci on wtci.wo = wo.wo and wtc.pn = wtci.task_card_pn and wtc.PN_sn = wtci.task_card_pn_sn
where wo.schedule_start_date between sysdate - 3 and sysdate + 3
and wtci.main_skill = 'YES'
group by wo.schedule_start_date,location,
order by location;

select wtci.status from wo_task_Card_item wtci
left outer join wo on wo.wo = wtci.wo
where location = 'BNE'
and wo.status = 'CANCEL'
order by man_hours desc;

select A.schedule_start_date, location, sum(A.days)as Hours from 
(select wo.wo, wo.schedule_start_date, location, round(sum(man_hours) / ((trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date))+1),2)  as Days from wo_task_card_item wtci
left outer join wo on wo.wo = wtci.wo
where wo.schedule_start_date between sysdate - 3 and sysdate + 3 
and main_skill = 'YES'
and wo.status 
group by wo.wo,wo.schedule_start_date, location,trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date) 
order by location)A
group by A.schedule_start_date, A.location
order by a.location;

select wo, location, trunc(schedule_completion_date)- trunc(schedule_start_date)  as Days from wo
where schedule_start_date = '08/Oct/15';
---Locate deferred
select count(wo)as Deferred,schedule_start_date, status from wo_task_card
where schedule_start_date between sysdate - 3 and sysdate + 3
and status = 'CANCEL'
group by schedule_start_date, status;
---Located Acheived
select count(wo)as Achieved,schedule_start_date, status from wo_task_card
where schedule_start_date between sysdate - 3 and sysdate + 3
and status = 'CLOSED'
group by schedule_start_date, status;
--deferred hours
select wo.location, round(sum(man_hours) / ((trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date))+1),2)as deferred, wtc.schedule_start_date from wo_task_card wtc
left outer join wo_task_card_item wtci on wtci.wo = wtc.wo and wtc.task_card = wtci.task_card and wtc.pn = wtci.task_card_pn and wtc.PN_sn = wtci.task_card_pn_sn
left outer join wo on wo.wo = wtc.wo
where wtc.schedule_start_date between sysdate - 3 and sysdate + 3
and wtc.status = 'CANCEL'
group by wo.location, wtc.schedule_start_Date,trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date)
order by wo.location;
--acheived hours
select wo.location, round(sum(man_hours) / ((trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date))+1),2)as Achieved, wtc.schedule_start_date from wo_task_card wtc
left outer join wo_task_card_item wtci on wtci.wo = wtc.wo and wtc.task_card = wtci.task_card and wtc.pn = wtci.task_card_pn and wtc.PN_sn = wtci.task_card_pn_sn
left outer join wo on wo.wo = wtc.wo
where wtc.schedule_start_date between sysdate - 3 and sysdate + 3
and wtc.status = 'CLOSED'
group by wo.location, wtc.schedule_start_Date,trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date)
order by location;


--combined

--allocated
select Ach.schedule_start_date, Ach.Location,Ach.Hours, acha.Achieved,achd.deferred From
                      (select A.schedule_start_date, location, sum(A.days)as Hours from 
                      (select wo.wo, wo.schedule_start_date, location, round(sum(man_hours) / ((trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date))+1),2)  as Days from wo_task_card_item wtci
                      left outer join wo on wo.wo = wtci.wo
                      where wo.schedule_start_date between sysdate - 4 and sysdate + 3 
                      and main_skill = 'YES'
                      group by wo.wo,wo.schedule_start_date, location,trunc(wo.schedule_completion_date)- trunc(wo.schedule_start_date) 
                      order by location)A
                      group by A.schedule_start_date,A.location
                      order by a.location)Ach
                      
--achieved
join (select wo.location, sum(man_hours)as Achieved, wo.schedule_start_date from wo_task_card wtc
                      left outer join wo_task_card_item wtci on wtci.wo = wtc.wo and wtc.task_card = wtci.task_card and wtc.pn = wtci.task_card_pn and wtc.PN_sn = wtci.task_card_pn_sn
                      left outer join wo on wo.wo = wtc.wo
                      where wo.schedule_start_date between sysdate - 4 and sysdate + 3
                      and wtc.status = 'CLOSED'
                      group by wo.location, wo.schedule_start_date
                      order by location)acha
on  acha.location = ach.location and acha.schedule_start_date = ach.schedule_start_date                      
--deffered
left outer join (select wo.location, sum(man_hours) as deferred, wo.schedule_start_date from wo_task_card wtc
                      left outer join wo_task_card_item wtci on wtci.wo = wtc.wo and wtc.task_card = wtci.task_card and wtc.pn = wtci.task_card_pn and wtc.PN_sn = wtci.task_card_pn_sn
                      left outer join wo on wo.wo = wtc.wo
                      where wo.schedule_start_date between sysdate - 4 and sysdate + 3
                      and wtc.status = 'CANCEL'
                      group by wo.location, wo.schedule_start_date
                      order by wo.location)achd
on achd.location = ach.location and achd.schedule_start_date = ach.schedule_start_date     