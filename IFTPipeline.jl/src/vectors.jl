using LinearAlgebra: dot, det, norm

θs = [0, π / 2, 7π / 8, 15π / 16, π, 17π / 16, 9π / 8]

unit_vector(θ) = [cos(θ); sin(θ)] / norm([cos(θ); sin(θ)])
unit_vector(θs[1])
unit_vector(θs[2])
unit_vectors = [unit_vector(θ) for θ in θs]

normalized_dot_product(a, b) = dot(a, b) / (norm(a) * norm(b))
[(; a, b, p=normalized_dot_product(a, b)) for a in unit_vectors, b in unit_vectors]

angle_between_vectors(a, b) = acos(round(dot(a, b) / (norm(a) * norm(b)); sigdigits=16))

[(; a, b, θ=angle_between_vectors(a, b)) for a in unit_vectors, b in unit_vectors]

angle_between_angles(θ1, θ2) = angle_between_vectors(unit_vector(θ1), unit_vector(θ2))
[(; θ1, θ2, θ=angle_between_angles(θ1, θ2)) for θ1 in θs, θ2 in θs]

θs = [17π / 16, -15π / 16, π, 15π / 16, -17π / 16, 0]
[(; θ1, θ2, θ=angle_between_angles(θ1, θ2)) for θ1 in θs, θ2 in θs]

oriented_angle_between_vectors(a, b) = atan(det(hcat(a, b)), dot(a, b))
unit_vectors = [unit_vector(θ) for θ in θs]
[(; a, b, θ=oriented_angle_between_vectors(a, b)) for a in unit_vectors, b in unit_vectors]

unit_vectors = [unit_vector(θ) for θ in [0, π / 4]]
[(; a, b, θ=oriented_angle_between_vectors(a, b)) for a in unit_vectors, b in unit_vectors]