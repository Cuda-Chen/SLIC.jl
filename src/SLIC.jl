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
    img_lab = Lab.(img)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
    S = Integer(sqrt((image_height * image_width) / K))
    clusters = Cluster[] # The properties of each cluster
    labels = Dict() # Label of each pixel
    distance = Matrix(Inf, image_height, image_width) # Distance matrix of each pixel to belonging cluster
    pixels_count = Array{Integer}(0, # Pixel counts of each cluster

    # Initialize each cluster and its fields
    idx = 1
    for x = div(S, 2):S:image_width
        for y = div(S, 2):S:image_height
            clusters.push!(Cluster(img_lab[y][x][1],
                                   img_lab[y][x][2],
                                   img_lab[y][x][3],
                                   y,
                                   x))
            idx += 1
        end
    end

    # Move the center of each cluster to the local lowgest gradient position
    function get_gradient(y, x)
        if x + 1 > image_width x = image_width - 2 end
        if y + 1 > image_height y = image_height - 2 end

        return image_lab[y + 1][x + 1][1] - image_lab[y][x][1] + \
               image_lab[y + 1][x + 1][2] - image_lab[y][x][2] + \
               image_lab[y + 1][x + 1][3] - image_lab[y][x][3]
    end
    for cluster in clusters:
        # Get current gradient of this center
        current_gradient = get_gradient(cluster.y, cluster.x)

        for dh = -1:1
            for dw = -1:1
                _y = cluster.y + dh
                _x = cluster.x + dw
                new_gradient = get_gradient(_y, _x)
                if new_gradient < current_gradient
                    cluster.l = image_lab[_y][_x][1]
                    cluster.a = image_lab[_y][_x][2]
                    cluster.b = image_lab[_y][_x][3]
                    cluster.y = _y
                    cluster.x = _x

                    current_gradient = new_gradient
                end
            end
        end
    end

    # SLIC superpixle calculation
    function cluster_pixels()
        for cluster in clusters
            for x = (cluster.x - 2 * S):(cluster.x + 2 * S)
                if x <= 0 || x > image_width continue end

                for y = (cluster.y - 2 * S):(cluster.y + 2 * S)
                    if y <= 0 || y > image_height continue end

                    L = image_lab[y][x][1]
                    A = image_lab[y][x][2]
                    B = image_lab[y][x][3]
                    Dc = sqrt((L - cluster.l)^2 + 
                              (A - cluster.a)^2 +
                              (B - cluster.b)^2)
                    Ds = sqrt((y - cluster.y)^2 +
                              (x - cluster.x)^2)
                    D = sqrt((Dc / M)^2 + (Ds / S)^2)

                    if D < distance[y][x]
                        if hashkey(labels, (y, x))
                            labels[(y, x)] = cluster
                            cluster.pixels.push!((y, x))
                        else
                            pop!(labels[(y, x)].pixels, (y, x))
                            labels[(y, x)] = cluster
                            cluster.pixels.push!((y, x))
                        end
                    end
                    distance[y][x] = D
                end
            end
        end
    end
    function update_cluster_position()
        for cluster in clusters
            sum_h = sum_w = 0
            pixel_count = pixels.size()

            for pixel in pixels
                sum_h += pixel[1]
                sum_w += pixel[2]
            end

            new_y = div(sum_h, pixel_count)
            new_x = div(sum_w, pixel_count)
            cluster.l = image_lab[new_y][new_x][1]
            cluster.a = image_lab[new_y][new_x][2]
            cluster.b = image_lab[new_y][new_x][3]
            cluster.y = new_y
            cluster.x = new_x
        end
    end
    for i = 1:iterations
        cluster_pixels()
        update_cluster_position()
    end

    # Create output image
    out_image = image_lab.copy()
    for cluster in clusters
        for pixel in cluster.pixels
            out_image[pixel[1]][pixel[2]][1] = cluster.l
            out_image[pixel[1]][pixel[2]][2] = cluster.a
            out_image[pixel[1]][pixel[2]][3] = cluster.b
        out_image[cluster.y][cluster.x][1] = 0
        out_image[clsuter.y][cluster.x][2] = 0
        out_image[cluster.y][cluster.x][3] = 0
        end
    end
    out_image = RGB(out_image)

    # Return processed result
    return out_image
end

