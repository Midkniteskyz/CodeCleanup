select 
  isnull(
    (
      select 
        cast(
          concat(
            c.name, 
            ' - ', 
            p.PercentCPU, 
            ' % ', 
            CHAR(10)
          ) as XML
        ) 
      from 
        nodes n 
        join APM_Application a on a.nodeid = n.nodeid 
        join apm_component c on c.ApplicationID = a.id 
        and isnull(c.IsDisabled, 0)= 0 
        join APM_Process_Detail p on p.ComponentID = c.id 
      where 
        n.nodeid = ${N = SwisEntity;
M = NodeID} 
and p.percentcpu > 0 
order by 
  percentcpu desc FOR XML PATH('')
), 
' None '
)
