using Images

struct Cluster
    l
    a
    b
    x
    y
    cluster_index
end

function slic(img, K, M, iterations=10)
    img_lab = Lab.(img)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
    S = Integer(sqrt((image_height * image_width) / K))
    clusters = Cluster[]
    labels = Dict()
    distance = Matrix(Inf, image_height, image_width)

    # Initialize each cluster and its fields
    idx = 1
    for x = div(S, 2):S:image_width
        for y = div(S, 2):S:image_height
            clusters.push!(Cluster(img_lab[y][x][1],
                                   img_lab[y][x][2],
                                   img_lab[y][x][3],
                                   x,
                                   y,
                                   idx))
            idx += 1
        end
    end

    # Move the center of each cluster to the local lowgest gradient position
    for cluster in clusters:
        # Get current gradient of this center
        ####
end

