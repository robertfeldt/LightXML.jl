# LightXML currently has free for XMLDocuments but not for XMLElements.
# Handling this is complex. Here we try to replicate the mem leak
# so we can try to later avoid it.

using LightXML

deltachars = int('z') - int('a')
randstr(maxlen) = join(map(i->char(int('a') + rand(0:deltachars)), 1:rand(1:maxlen)))

function random_xmlelem_tree(maxdepth = 10)
  xmlelement = new_element(randstr(8))
  for r in 1:rand(1:5)
    p = rand()
    if p < 0.50 && maxdepth > 0
      add_child(xmlelement, random_xmlelem_tree(maxdepth-1))
    elseif p < 0.75
      set_attribute(xmlelement, randstr(5), randstr(10))
    else
      add_text(xmlelement, randstr(20))
    end
  end
  return xmlelement
end

function random_xml_doc(maxdepth = 10)
  xdoc = XMLDocument()
  set_root(xdoc, random_xmlelem_tree(maxdepth))
  (length(ARGS) >= 2 && ARGS[2] == "free") ? finalizer(xdoc, free) : nothing
  xdoc
end

sumsizes = 0

for i in 1:2000
  xmls = Any[]
  for j in 1:200
    x = (length(ARGS) >= 1 && ARGS[1] == "xdoc") ? random_xml_doc() : random_xmlelem_tree()
    push!(xmls, x)
  end
  # We don't really use the xmls for anything, just check their size and then let go
  sumsizes += sum(map(xe -> length(string(xe)), xmls))
  print("."); flush(STDOUT);
  gc() # Should be able to get back all of the xml-related mem here...
end

# When we get here we should only need to have a ref to size left, not to any of the
# XMLElements. Notify user and sleep so that they can check mem use.
println("Total size: ", size)
println("Calculation ready and GC'd. Check mem use of this Julia process!")
sleep(3600) # Sleep an hour... ;)
