using Images

mutable struct Cluster
    l
    a
    b
    y
    x
    #pixels = []
    #cluster_index
end

function slic(img, K, M, iterations=10)
    println("Initialize internel parameters")
    img_lab = Lab.(img)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
    S = round(Int, (sqrt((image_height * image_width) / K)))
    clusters = Cluster[] # The properties of each cluster
    #labels = Dict() # Label of each pixel
    labels = fill(-1, image_height, image_width) # Label of each pixel
    distance = fill(Inf, image_height, image_width) # Distance matrix of each pixel to belonging cluster
    pixels_count = Integer[] # Pixel counts of each cluster

    # Initialize each cluster and its fields
    println("Initialize each cluster and its fields")
    for x = div(S, 2):S:image_width
        for y = div(S, 2):S:image_height
            push!(clusters, Cluster(img_lab[y, x].l,
                                   img_lab[y, x].a,
                                   img_lab[y, x].b,
                                   y,
                                   x))
            push!(pixels_count, 0)
        end
    end

    # Move the center of each cluster to the local lowgest gradient position
    function get_gradient(y, x)
        if x + 1 > image_width x = image_width - 2 end
        if y + 1 > image_height y = image_height - 2 end

        return img_lab[y + 1, x + 1].l - img_lab[y, x].l + \
               img_lab[y + 1, x + 1].a - img_lab[y, x].a + \
               img_lab[y + 1, x + 1].b - img_lab[y, x].b
    end
    println("Move the center of each cluster to the local lowgest gradient position")
    for cluster in clusters
        # Get current gradient of this center
        current_gradient = get_gradient(cluster.y, cluster.x)

        for dh = -1:1
            for dw = -1:1
                _y = cluster.y + dh
                _x = cluster.x + dw
                new_gradient = get_gradient(_y, _x)
                if new_gradient < current_gradient
                    cluster.l = img_lab[_y, _x].l
                    cluster.a = img_lab[_y, _x].a
                    cluster.b = img_lab[_y, _x].b
                    cluster.y = _y
                    cluster.x = _x

                    current_gradient = new_gradient
                end
            end
        end
    end

    # SLIC superpixle calculation
    function cluster_pixels()
        for i = 1:clusters.size()
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
        for i = 1:clusters.size()
           clusters[i].y = clusters[i].x = pixel_count[i] = 0 
        end

        # Compute the new position of new cluster center
        for x in 1:image_width
            for y in 1:image_height
                label_index = labels[y, x]
                if label_index == -1 continue end

                clusters[label_index].y = y
                clusters[label_index].x = x
                pixel_count[label_index] += 1
            end
        end

        for cluster in clusters
            new_y = div(cluster.y, pixel_count)
            new_x = div(cluster.x, pixel_count)
            cluster.l = img_lab[new_y, new_x].l
            cluster.a = img_lab[new_y, new_x].a
            cluster.b = img_lab[new_y, new_x].b
            cluster.y = new_y
            cluster.x = new_x
        end
    end
    for i = 1:iterations
        println("SLIC iteration $(i) ...")
        cluster_pixels()
        update_cluster_position()
    end

    # Create output image
    # The color of each cluster is as same as its center
    # except the center
    out_image = img_lab.copy()
    for x = 1:image_width
        for y = 1:image_height
            out_image[y, x].l = clusters[labels[y, x]].l
            out_image[y, x].a = clusters[labels[y, x]].a
            out_image[y, x].b = clusters[labels[y, x]].b
        end
    end
    out_image = RGB(out_image)

    # Return processed result
    return out_image
end

