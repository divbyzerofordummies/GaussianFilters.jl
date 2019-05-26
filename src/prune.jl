"""
    prune(x,T,U,J_max)

Prune the posterior Gaussian-Mixture

Arguments:
	x: posterior Gaussian-Mixture
	T: truncation threshold
	U: merging threshold
	J_max: maximum number of features
"""
function prune(x,T,U,J_max)
	l = 0
	J_k = x.N
	n = length(x.μ[1,:])

	# prune indices based on truncation threshold
	I = collect(1:J_k)
	I = I[x.w.>T]

	# setup output vectors
	w_new = zeros(J_max,1)
	μ_new = zeros(J_max,n)
	Σ_new = zeros(J_max,n,n)

	# perform pruning
	while length(I) != 0
		l = l+1
		j = argmax(x.w[I])

		# Merge close features
		L = []
		for i in I
			delta = x.μ[i,:]-x.μ[j,:]
			if dot(delta, inv(x.Σ)*delta) < U
				push!(L,i)
			end
		end

		# determine merged parameters
		w_tilde = sum(x.w[L])
		μ_tilde = 1/w_tilde * dot(x.w[L],x.μ[L,:])
		Σ_tilde = zeros(n,n)
		for i in L
			tmp = x.Σ[i,:,:] + outer(μ_tilde-x.μ[i,:],μ_tilde-x.μ[i,:])
			Σ_tilde += dot(x.w[i],tmp)
		end
		Σ_tilde = 1/w_tilde * Σ_tilde

		# store values
		w_new[l] = w_tilde
		μ_new[l,:] = μ_tilde
		Σ_new[l,:,:] = Σ_tilde

		# prune merged features
		I = setdiff(I,L)
	end


	if l > J_max 	# only keep the J_max with highest weights
		idxs = sort!([1:size(w_new);], by=i->(w_new[i]), rev=true)
		idxs = idxs[1:J_max]
		w_new = w_new[idxs]
		μ_new = μ_new[idxs,:]
		Σ_new = Σ_new[idxs,:,:]
	else		# drop zeros at end
		w_new = w_new[1:l]
		μ_new = μ_new[1:l,:]
		Σ_new = Σ_new[1:l,:,:]
	end

	N = length(w_new)
	x_new = GaussianMixture(N,w_new,μ_new,Σ_new)
	return x_new
end
