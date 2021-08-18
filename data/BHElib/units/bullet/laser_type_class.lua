---------------------------------------------------------------------------------------------------
---laser_type_class.lua
---author: Karl
---date: 2021.8.8
---references: THlib/laser/laser.lua
---desc: Defines LaserType, an object of this class stores information about the texture of a laser.
---     One object may consist of versions of the same kind of laser (typically with different colors)
---------------------------------------------------------------------------------------------------

---@class LaserTypeClass
local M = LuaClass("LaserTypeClass")

---------------------------------------------------------------------------------------------------
---init

---l1, l2, l3 have to be positive integer
---@param index_to_images table a map from integer index to tables of 3 elements {head_img, body_img, tail_img}
---@param l1 number length of laser head in the image in pixels
---@param l2 number length of laser body in the image in pixels
---@param l3 number length of laser tail in the image in pixels
---@param width number width of the laser in the image in pixels
function M.__create(index_to_images, l1, l2, l3, width)
    local self = {
        index_to_images = index_to_images,
        l1 = l1,
        l2 = l2,
        l3 = l3,
        width = width,
    }
    return self
end

---this function will load the laser images from the texture
---and returns a laser type holding tables of those images;
---the rectangular sub-area of the texture file to load the image from is specified
---from the top-left (x, y) with a width of l1 + l2 + l3, a height fo num_row * row_height
---@param tex_name string name of the texture to load laser from
---@param image_name_prefix string a unique prefix for the image arrays loaded from the texture
---@param num_row number number of rows
---@param row_height number height of each row in pixels
---@param l1 number width of laser head in the image in pixels
---@param l2 number width of laser body in the image in pixels
---@param l3 number width of laser tail in the image in pixels
function M.declareTypeFromTexture(tex_name, image_name_prefix, num_row, row_height, l1, l2, l3)
    -- load three arrays of images, each store image names for head, body and tail
    local head_image_array_prefix = image_name_prefix.."_head"
    local body_image_array_prefix = image_name_prefix.."_body"
    local tail_image_array_prefix = image_name_prefix.."_tail"

    LoadImageArray(head_image_array_prefix, tex_name, 0, 0, l1, row_height, 1, num_row)
    LoadImageArray(body_image_array_prefix, tex_name, l1, 0, l2, row_height, 1, num_row)
    LoadImageArray(tail_image_array_prefix, tex_name, l1 + l2, 0, l3, row_height, 1, num_row)
    local center_y = row_height * 0.5
    for i = 1, num_row do
        SetImageCenter(head_image_array_prefix..i, 0, center_y)
        SetImageCenter(body_image_array_prefix..i, 0, center_y)
        SetImageCenter(tail_image_array_prefix..i, 0, center_y)
    end

    local index_to_images = {}
    for i = 1, num_row do
        index_to_images[i] = {
            head_image_array_prefix..i,
            body_image_array_prefix..i,
            tail_image_array_prefix..i,
        }
    end
    local LaserType = M(index_to_images, l1, l2, l3, row_height)
    return LaserType
end

---------------------------------------------------------------------------------------------------
---instance methods

local int = int

---@param index number the index to check
---@return boolean true if the index is in range of support of this laser type; false otherwise
function M:checkValidIndex(index)
    return int(index) == index and index >= 1 and index <= #self.index_to_images
end

---get the images corresponding to the laser variation specified by the given index
---@return string, string, string image names of the head image, body image and tail image
function M:getImagesForIndex(index)
    local images = self.index_to_images[index]
    return images[1], images[2], images[3]
end

---@return number,number,number length of laser head, body and tail in pixels
function M:getImageLengthByParts()
    return self.l1, self.l2, self.l3
end

---@return number width of a laser
function M:getImageWidth()
    return self.width
end

return M