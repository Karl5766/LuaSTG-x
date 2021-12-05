
local hot_iter = HotIter()
if external_objects.hot_iter then
    hot_iter:inheritIndices(external_objects.hot_iter)
end
external_objects.hot_iter = hot_iter