#- remove comments from rules
  iptables-save  | sed -e 's/-m comment --comment "\?[^"]\+"\? -j/-j/'  | iptables-restore
  ip6tables-save | sed -e 's/-m comment --comment "\?[^"]\+"\? -j/-j/' | ip6tables-restore
 
