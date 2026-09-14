-- Pedido do dono do produto: no 4-1-2-1-2 os laterais e os MC's ficam
-- espremidos perto do centro. So a formacao base (nao a variante "(2)",
-- que usa LM/RM em vez de CM e nao foi mencionada) -- LB/RB abrem de
-- 0.14/0.86 para 0.06/0.94, CM1/CM2 de 0.34/0.66 para 0.26/0.74.

update public.fc_formation_slots
set x = 0.06
where formation_code = '4-1-2-1-2' and slot_code = 'LB';

update public.fc_formation_slots
set x = 0.94
where formation_code = '4-1-2-1-2' and slot_code = 'RB';

update public.fc_formation_slots
set x = 0.26
where formation_code = '4-1-2-1-2' and slot_code = 'CM1';

update public.fc_formation_slots
set x = 0.74
where formation_code = '4-1-2-1-2' and slot_code = 'CM2';
