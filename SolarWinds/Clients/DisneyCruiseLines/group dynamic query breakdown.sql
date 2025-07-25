
filter:/Orion.Nodes[Pattern(Caption,'abcd') AND 
Caption='abcd' AND 
Caption!='abcd' AND 
StartsWith(Caption,'abcd') AND 
EndsWith(Caption,'abcd') AND 
Contains(Caption,'abcd')]

Dynamic Query Filters

Is
Nodes.Caption = 'abcd'

Is Not
Nodes.Caption <> 'abcd' OR Nodes.Caption IS NULL

Begins With
Nodes.Caption LIKE 'abcd%'

Ends With
Nodes.Caption LIKE '%abcd'

Contains
Nodes.Caption LIKE '%abcd%'

Matches
Nodes.Caption LIKE 'abcd'