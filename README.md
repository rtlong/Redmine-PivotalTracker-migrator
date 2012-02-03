Use this line to copy all stories from one project to another. Make sure integrations match, and the point scheme:

```
id_map = {}; refable_project = PivotalTracker::Project.find(421561); temp_project = PivotalTracker::Project.find(469475); temp_project.stories.all.each{|s| s.delete }; refable_project.stories.all.each{|s| n = s.instance_values; n.delete_if{|k,v| k.match(/id|url|created_at|project_id|errors|owned_by|requested_by/i) or v.nil? }; n['integration_id'] = 11335 unless n['integration_id'].nil? ; if n['current_state'].to_s.match(/accepted/);  n['current_state'] = (case n['story_type']; when 'release' then 'unstarted'; when 'chore' then 'started'; else 'delivered'; end); end; n = temp_project.stories.create(n); p n; puts n.errors.to_a; id_map[s.id] = n.id }; y id_map
```

It will print out a YAML ID map to map story ids for testing