using Images

# struct to store the Lab color values
# and center position of each cluster
mutable struct Cluster
    l
    a
    b
    y
    x
end

function slic(img, K, M, iterations=10, connectivity=false)
    img_lab = Lab.(img)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
    S = round(Int, (sqrt((image_height * image_width) / K)))
    clusters = Cluster[] # The properties of each cluster
    labels = fill(-1, image_height, image_width) # Label of each pixel
    distance = fill(Inf, image_height, image_width) # Distance matrix of each pixel to belonging cluster
    pixel_count = Integer[] # Pixel counts of each cluster

    # Initialize each cluster and its fields
    for x = div(S, 2):S:image_width
        for y = div(S, 2):S:image_height
            push!(clusters, Cluster(img_lab[y, x].l,
                                   img_lab[y, x].a,
                                   img_lab[y, x].b,
                                   y,
                                   x))
            push!(pixel_count, 0)
        end
    end

    # Move the center of each cluster to the local lowgest gradient position
    function get_gradient(y, x)
        if x + 1 > image_width x = image_width - 2 end
        if y + 1 > image_height y = image_height - 2 end

        return img_lab[y + 1, x + 1].l - img_lab[y, x].l + 
               img_lab[y + 1, x + 1].a - img_lab[y, x].a + 
               img_lab[y + 1, x + 1].b - img_lab[y, x].b
    end
    for i = 1:length(clusters)
        # Get current gradient of this center
        current_gradient = get_gradient(clusters[i].y, clusters[i].x)

        for dh = -1:1
            for dw = -1:1
                _y = clusters[i].y + dh
                _x = clusters[i].x + dw
                new_gradient = get_gradient(_y, _x)
                if new_gradient < current_gradient
                    clusters[i].l = img_lab[_y, _x].l
                    clusters[i].a = img_lab[_y, _x].a
                    clusters[i].b = img_lab[_y, _x].b
                    clusters[i].y = _y
                    clusters[i].x = _x

                    current_gradient = new_gradient
                end
            end
        end
    end

    # SLIC superpixle calculation
    function cluster_pixels()
        for i = 1:length(clusters)
            for x = (clusters[i].x - 2 * S):(clusters[i].x + 2 * S)
                if x <= 0 || x > image_width continue end

                for y = (clusters[i].y - 2 * S):(clusters[i].y + 2 * S)
                    if y <= 0 || y > image_height continue end

                    L = img_lab[y, x].l
                    A = img_lab[y, x].a
                    B = img_lab[y, x].b
                    Dc = sqrt((L - clusters[i].l)^2 + 
                              (A - clusters[i].a)^2 +
                              (B - clusters[i].b)^2)
                    Ds = sqrt((y - clusters[i].y)^2 +
                              (x - clusters[i].x)^2)
                    D = sqrt((Dc / M)^2 + (Ds / S)^2)

                    if D < distance[y, x]
                        distance[y, x] = D
                        labels[y, x] = i
                    end
                end
            end
        end
    end
    function update_cluster_position()
        # Clear the position value and pixel counts of each cluster 
        for i = 1:length(clusters)
           clusters[i].y = clusters[i].x = pixel_count[i] = 0 
        end

        # Compute the new position of new cluster center
        for x in 1:image_width
            for y in 1:image_height
                label_index = labels[y, x]
                if label_index == -1 continue end

                clusters[label_index].y += y
                clusters[label_index].x += x
                pixel_count[label_index] += 1
            end
        end

        # Assign the new position to each cluster
        for i = 1:length(clusters)
            new_y = div(clusters[i].y, pixel_count[i])
            new_x = div(clusters[i].x, pixel_count[i])
            clusters[i].l = img_lab[new_y, new_x].l
            clusters[i].a = img_lab[new_y, new_x].a
            clusters[i].b = img_lab[new_y, new_x].b
            clusters[i].y = new_y
            clusters[i].x = new_x
        end
    end
    @time for i = 1:iterations
        println("SLIC iteration $(i) ...")
        cluster_pixels()
        update_cluster_position()
    end

    # Enforce connectivity
    # Reference: https://github.com/scikit-image/scikit-image/blob/7e4840bd9439d1dfb6beaf549998452c99f97fdd/skimage/segmentation/_slic.pyx#L240-L348
    function enforce_connectivity(labels, min_size, max_size, start_label=1)
        depth = 1 # reserved for supervoxel used, now set to 1
        height = size(labels, 1)
        width = size(labels, 2)

        dx = [1, -1, 0, 0]
        dy = [0, 0, 1, -1]
        #dz = [] # reserved for supervoxel used
       
        # indicates that the label of this pixel has not been assigned
        mask_label = start_label - 1
        labels_final = fill(mask_label, height, width)

        current_new_label = start_label
        #label = start_label

        # used for BFS
        current_segment_size = 1
        bfs_visited = 0

        # store neighboring pixels
        # now set the dimension to 2 because we are using superpixel
        coord_list = fill(0, max_size, 2)

        for x = 1:width
            for y = 1:height
                if labels[y, x] == mask_label continue end
                if labels_final[y, x] > mask_label continue end

                adjacent = 0
                label = labels[y, x]
                labels_final[y, x] = current_new_label
                current_segment_size = 1
                bfs_visited = 0
                coord_list[bfs_visited + 1, 1] = y
                coord_list[bfs_visited + 1, 2] = x

                # Preform BFS to find the size of superpixel with 
                # same lable number
                while bfs_visited < current_segment_size <= max_size
                    for i = 1:4
                        yy = coord_list[bfs_visited + 1, 1] + dy[i]
                        xx = coord_list[bfs_visited + 1, 2] + dx[i]

                        if 1 <= yy <= height &&  1 <= xx <= width
                            if labels[yy, xx] == label && labels_final[yy, xx] == mask_label
                                labels_final[yy, xx] = current_new_label
                                coord_list[current_segment_size + 1, 1] = yy # <-- index problem in the future
                                coord_list[current_segment_size + 1, 2] = xx # <-- index problem in the future
                                current_segment_size += 1
                                
                                if current_segment_size > max_size break end
                            elseif labels_final[yy, xx] > mask_label &&
                                   labels_final[yy, xx] != current_new_label
                                adjacent = labels_final[yy, xx]
                            end
                        end
                    end
                    bfs_visited += 1
                end

                #for i = 1:current_segment_size println(coord_list[i, 1]) end
                #println(max_size, " ", current_segment_size)

                # merge the superpixel to its neighbor if it is too small
                if current_segment_size < min_size
                    @inbouds @simd for i = 1:current_segment_size
                        #println(i, " ", coord_list[i, 1])
                        labels_final[coord_list[i, 1],
                                     coord_list[i, 2]] = adjacent
                    end
                else
                    current_new_label += 1
                end
            end
        end

        return labels_final
    end
    if connectivity
        segment_size = image_height * image_width / size(clusters, 1)
        labels = enforce_connectivity(labels, round(Int, 0.5 * segment_size), round(Int, 3.0 * segment_size))
    end

    print(size(labels))
    print(size(clusters))
    print(labels[1, 1])

    # Create output image
    # The color of each cluster is as same as its center
    # except the center
    out_image = copy(img_lab)
    for x = 1:image_width
        for y = 1:image_height
            out_image[y, x, :] .= Lab(clusters[labels[y, x]].l,
                                   clusters[labels[y, x]].a,
                                   clusters[labels[y, x]].b)
        end
    end
    out_image = RGB.(out_image)

    # Return processed result
    return out_image
end
