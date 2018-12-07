# YAML

- Yet Another Markup Language
- It takes concepts from familiar agile processes 
- It relies on indentation, colons and dashes.
- It is mostly used in configuration files
- Easy to implement and use

YAML uses indentation for grouping things that go together.
Dashes are used for list
Colons are used for listing things that go together as in JSON. Space after colon is essential.
YAML support UTF-8, UTF-16 and UTF-32 (mandatory for JSON compatibility).

The below style of YAML is called Block style.

```yaml
host: phl-42
datacenter:
  location: Philadelphia
  cab: 13
roles: 
  - web
  - dns
```

Another style which is Flow-styles which is an extension of JSON.

```yaml
host: "phl-42"
datacenter: { location: Philadelphia, cab: 13 }
roles: [ web, dns ]
```

- Create Mappings of servers in data-center.
- YAML requires two spaces for indentation. We cannot duplicate the keys once it is assigned at the same level.
- We can assign collections as lists. To specify lists for roles, we need to add colon at the end and then indent the elements as list. Here roles include webserver, wp_database.
- We don't need to use double quotes for values. It can accept spaces.
- We can convert numbers into string using double quotes or single quotes.
- For multiline values, we can use vertical bar (|)
- We can use (>) to eliminate new lines.
- Three dashes are used for adding multiple documents in single file. We can add another --- dashes for adding another host. 
- We can also use triple dots for signalling end of this collection. Then, we can use three dashes to add another documents which are not related to first documents.
- We can add comments using hashes
- Tags can be used for set custom URI, to set local tags (tag relevant to existing yaml file.) and for setting a data type.
- Tags are defined using % sign and ! marks
- We can specify data type using double exclamation marks (!!). The data types include seq (Sequence), map (Map), str (String), int (Integer), float (Float), null (Null), binary (Binary), omap (Ordered map), set (Unordered set).


```yaml
---
%TAG ! tag:hostdata:phl:
# hosts.yaml
# It can have any extension
host: phl-42
datacenter: 
  location: !PHL Philadelphia
  cab: !!str 13
  cab_unit: !!str 3
roles:
  - webserver
  - wp_database
downtime_sch: |
  2018-10-31 - kernel upgrade
  2019-02-02 - security fix
comments: >
  Experiencing high I/O
  since 2018-10-01.
  Currently investigating.
---
host: phl-43
datacenter:
  location: Philadelphia
  cab: "13"
  cab_unit: "4"
...
---
host: hel-13
datacenter: 
  location: Helsinka
  cab: "9"
  cab_unit: "1-2"
...
```

- If we want to use data again, we can use anchor like functions. Anchors are defined using ampersand (&) and are referenced using (*) symbol. When assigning anchor, it will take the local anchor reference just like in any programming language.

```yaml
---
%TAG ! tag:hostdata:phl:
# hosts.yaml
# It can have any extension
host: phl-42
datacenter: 
  location: &PHL Philadelphia
  cab: !!str 13
  cab_unit: !!str 3
roles: &wphost
  - webserver
  - wp_database
downtime_sch: |
  2018-10-31 - kernel upgrade
  2019-02-02 - security fix
comments: >
  Experiencing high I/O
  since 2018-10-01.
  Currently investigating.
---
host: phl-43
datacenter:
  location: *PHL
  cab: "13"
  cab_unit: "4"
roles: *wphost
...
---
host: hel-13
datacenter: 
  location: Helsinka
  cab: "9"
  cab_unit: "1-2"
...
```