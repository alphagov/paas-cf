endpoint=$(cf api | grep "^API endpoint:" | rev | cut -d' ' -f1 | rev)
echo "endpoint: $endpoint"

for org in $(cf orgs | grep -v "^name$" | grep -v "^Getting orgs as" | grep -v "^$"); do
  cf target -o "$org" >/dev/null 2>&1
  for space in $(cf spaces | grep -v "^name$" | grep -v "^Getting spaces in" | grep -v "No spaces found" | grep -v "^$"); do
    cf target -o "$org" -s $space >/dev/null 2>&1
    as_serv=$(cf s | grep -v "^Getting service instances" | grep -v "^No service instances found" | grep -v "^name " | grep -v "^$" | tr -s " " | cut -d ' ' -f 1,2,3 | grep -i autoscal)
    if [[ $as_serv != "" ]]; then
      echo "  org: $org, space: $space"
      echo "    $as_serv"
    fi
  done
done
