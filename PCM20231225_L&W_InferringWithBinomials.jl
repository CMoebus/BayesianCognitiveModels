### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ ee68848a-fafb-45b0-a2a4-7ab41e65c6d7
begin
	using Turing,MCMCChains
	using LaTeXStrings
	using StatsPlots, Random
	using DataFrames
	using Optim
	using StatsBase
end # begin

# ╔═╡ 636d3550-a31b-11ee-3294-4f03381bbe16
md"
===================================================================================
#### Lee&Wagenmakers, ch 3: Inferring with Binomials
##### file: PCM20231225\_L&W_InferringWithBinomials.jl
##### Julia/Pluto.jl-code (1.10.1/19.36) by PCM *** 2023/12/31 ***

===================================================================================
"

# ╔═╡ 77f3e7bb-eee4-44be-a8d3-df7467b57ab8
md"
---
#### 1. Introduction to Turing in Simple Steps

We present here some reimplementations of WinBUGS models (Lee & Wagenmakers, 2013) in TURING.jl which itself is based on the *DynamicPPL.j* library ([Tarek et al., 2020](https://arxiv.org/ftp/arxiv/papers/2002/2002.02702.pdf)). While some scripts can be translated line by line others need to be reworked. This is due to the fact that WinBUGS is more abstract than TURING.jl. WinBUGS is strict *declarative* with no special order of declarations wheras TURING.jl is *procedural* where order of bindings and function calls is significant. 

Another problem with linewise transpilation is the fact that in TURING.j-models *only* the bindings of random variable *left of* '~' can be seen without further ado. Interesting *derived* quantities *not left of* '~' need special treatment to get analyzed. So e.g. if you are interested in the *difference* of two parameters $\delta= \theta_1 - \theta_2$ you have no trouble to display the *posterior* distribution of $\delta$ in WinBUGS. In contrast to that in TURING.jl you need special selector functions when looking for $\delta$. 

"

# ╔═╡ eb7e532c-ef0b-4b90-8329-5d97d0b54b27
md"
---
##### 1.1 Inferring a Rate $\theta$ with the *Beta-Binomial* Model 
([Lee & Wagenmakers, 2013](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B), ch. 3.1, p.37ff) 

---
###### 1.1.1 Model Function of *Beta-Binomial* Model
Here *line-by-line* transpilation of the model code from WinBUGS to TURING.jl is possible.

- **Prior:** *Beta*
- **Likelihood:** *Binomial*
"

# ╔═╡ 6d070d28-d200-40d8-96ad-552cfd495886
@model function BetaBinomial(n; k=missing)                    # L&W, p.37
	#--------------------------------------------------------------------
	# n = #trials, #experiments
	# k = #successes
	#--------------------------------------------------------------------
	# Beta Prior Distribution for Rate Θ
	Θ ~ Beta(1, 1) 
	# Binomial Likelihood
	k ~ Binomial(n, Θ)  # k sucesses in n trials
	#--------------------------------------------------------------------
	# Θ # (= return Θ)
	#--------------------------------------------------------------------
end # model

# ╔═╡ a5411ef8-0bc3-4746-b6b9-22ed85c272a5
md"
---
###### 1.1.2 Prior Model: $n$ is *observed* contrary to $k$, $θ$ is *latent*
  
"

# ╔═╡ df06018b-5ec7-4ce9-aa11-ded117c88db6
modelBetaBinomialPrior =
	let k =  6                     # = number of successes (not used here)
		n = 10                     # = number of random experiments
		BetaBinomial(n)
	end # let

# ╔═╡ 4689a3b1-5847-4422-9155-90a9e1948315
chainBetaBinomialPrior =
	let iterations = 5000
		sampler    = Prior()
		sample(modelBetaBinomialPrior, sampler, iterations)
	end # let

# ╔═╡ 79f58e4f-81a7-436d-a161-007185cfbf24
size(chainBetaBinomialPrior)

# ╔═╡ 4224e0aa-1895-438e-9d4e-9ae7c32202f4
md"
###### Prior results:
- prior distributions: $pdf(\theta) = \beta(1, 1)$ and $pmf(k)$ are approximately *uniform* distributions with 
-  $\mathbb E(\theta)$ = 0.5, $\mathbb E(k) = 5.0$ and
-  $\mathbb E(\hat{\theta})$ ≈ 0.5, $\mathbb E(\hat k) ≈ 5.0$ where $\hat x$ designates all *samples* $x$ drawn and collected in a MCM chain.
"

# ╔═╡ 8259f21a-f564-4aa9-8659-0433a18c98ef
describe(chainBetaBinomialPrior)

# ╔═╡ 0181790c-acad-4249-acd5-fe461384d1a5
plot(chainBetaBinomialPrior, bins=10, normalize=true)

# ╔═╡ 4c3b4428-120b-46da-9304-5f6bfd6bb7dc
MCMCChains.get_sections(chainBetaBinomialPrior, :parameters)

# ╔═╡ 3be1250c-104c-4b4c-b73e-30e2703e4d3b
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 35696e84-5c80-43a2-bbda-2ef5ccaf182f
#highest posterior density interval representing 1-alpha probability mass
hpd(chainBetaBinomialPrior, alpha=0.05)

# ╔═╡ f0c5e11c-53e5-4b64-8fd8-dd9f677923ee
hpd(chainBetaBinomialPrior)

# ╔═╡ 3a22d31a-3b8c-463f-81ca-28947032daa3
let k =  6
	n = 10
	θPrior = chainBetaBinomialPrior[:,1,1]
	#-------------------------------------------------------------------------
	# blue density plot of the prior
	density(θPrior; xlim=(-0.1, 1.1), size=(600, 300), legend=:best, lw=2, label=L"\hat\theta_{prior}", title=L"Rate\;\, \hat\theta_{prior}", xlabel=L"\hat θ", ylabel=L"density\; f(\hat θ)")
	# Visualize the true probability of heads in red
	vline!([k/n]; label=L"\theta_{prior}", colour=:red, lw=1.5)
	#-------------------------------------------------------------------------
end # let

# ╔═╡ 6863825f-3612-4355-99c6-b35ca643eb0f
md"
---
###### 1.1.3 Posterior Model: $n, k$ are *observed*,  $k$ is the *datum*, $θ$ is *latent*
  
"

# ╔═╡ 7d8ccb65-61fd-45a7-a666-6653d183c3bf
modelBetaBinomialPosterior = 
	let k = datum = 6
		n = 10
        BetaBinomial(n, k=datum) 
	end # let

# ╔═╡ 3f20b43c-ce24-416e-99cc-4269572c7b34
md"
---
###### [Sampler MH](https://turinglang.org/dev/docs/library/#Turing.Inference.MH)
"

# ╔═╡ 2d5cd3db-8e6a-4871-8d9f-129d2860dba3
chainBetaBinomialPosteriorMH = 
	let iterations = 4000
		sampler    = MH()
		sample(modelBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ 49fd413c-0e95-4437-a207-4abdeab585c0
md"
###### Posterior result:
-  $pdf(\theta_{posterior})$ is single peaked with $\mathbb E(\theta_{posterior}) = 0.599 \approx 0.6$.
"

# ╔═╡ 234d9cb7-bffa-4300-8f7e-4418ff3a271d
describe(chainBetaBinomialPosteriorMH)

# ╔═╡ 91b4672d-2562-4692-b86b-f517b6fd3bce
plot(chainBetaBinomialPosteriorMH)

# ╔═╡ 715ff1a9-d837-469f-895c-72fecb1bea42
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 5a542f6c-2c55-4cb5-8991-a2ad54da006a
hpd(chainBetaBinomialPosteriorMH, alpha=0.05)

# ╔═╡ d8837442-d3a9-4c42-8aea-b6f41ed705ef
let k =  6
	n = 10
	# blue density plot of the approximate posterior distribution using MH 
	density(chainBetaBinomialPosteriorMH; xlim=(0.0, 1.0), size=(600, 300), legend=:best, width=2, label=L"\hat\theta_{posterior}", title=L"Rate\;\, \hat\theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red, lw=1.5)
end # let

# ╔═╡ 97fb6210-9e84-4b05-9e64-760eba1f555b
md"
---
###### [Sampler HMC](https://turinglang.org/dev/docs/library/#Turing.Inference.HMC)
"

# ╔═╡ aef6bb12-070f-4dc4-be26-7eff68775653
chainBetaBinomialPosteriorHMC = 
	let iterations = 3000
		ϵ          = 0.05                # proposed by Quangtiencs
		τ          = 10                  # proposed by Quangtiencs
		sampler    = HMC(ϵ, τ)
		sample(modelBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ 881527e6-09e1-4d39-96dc-1040eb39575f
md"
###### Posterior result:
-  $pdf(\theta_{posterior})$ is single peaked with $\mathbb E(\theta_{posterior}) = 0.599 \approx 0.6$.
"

# ╔═╡ 39ff93a4-03bb-45d6-af8e-f3e25795470f
describe(chainBetaBinomialPosteriorHMC)

# ╔═╡ 86a88ba2-ede6-49b9-be3f-2dce4c180fd5
plot(chainBetaBinomialPosteriorHMC)

# ╔═╡ b270d43a-f8ae-48a4-aa6f-bb529249c927
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 96768615-fc0d-47d2-8ca5-412e0ee1223b
hpd(chainBetaBinomialPosteriorHMC)

# ╔═╡ 043d9abf-b949-450e-b74c-735836ef3c94
let k =  6
	n = 10
	# blue density plot of the approximate posterior distribution using HMC 
	density(chainBetaBinomialPosteriorHMC; xlim=(0.0, 1.0), size=(600, 300), legend=:best, width=2, label=L"\hat\theta_{posterior}", title=L"Rate\;\, \hat\theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red, lw=1.5)
end # let

# ╔═╡ 68977f18-407c-4a08-b1cd-2327178c09fc
md"
---
###### [Sampler HMCDA](https://turinglang.org/dev/docs/library/#Turing.Inference.HMC)
"

# ╔═╡ 2669fe6f-cf08-4b94-99ed-7f5f8da5cdc0
chainBetaBinomialPosteriorHMCDA =
	let iterations = 3000
		nBurnIn    = 1000              # samples in burnin phase
		δ          = 0.65              # acceptance rate. 65% is often recommended.
		ϵ          = 0.825             # Initial step size
		sampler    = HMCDA(nBurnIn, δ, ϵ)
		sample(modelBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ 1ff89e57-bb59-4cbe-8f85-3dd906646166
md"
###### Posterior result:
-  $pdf(\theta_{posterior})$ is single peaked with $\mathbb E(\theta_{posterior}) = 0.599 \approx 0.6$.
"

# ╔═╡ 956b6f85-fa96-40b3-9fb5-a03faa65e312
describe(chainBetaBinomialPosteriorHMCDA)

# ╔═╡ e6d19c9f-ebab-4ea4-85a1-df70dc5fda97
plot(chainBetaBinomialPosteriorHMCDA)

# ╔═╡ 7eb630a5-a246-43fa-9a4d-71e88e15c515
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 642d0e43-9ff0-406c-b3c1-f02e98dd8437
hpd(chainBetaBinomialPosteriorHMCDA)

# ╔═╡ d8bed0c2-2360-4b1d-b2b7-f17821722db8
let k =  6
	n = 10
	# blue density plot of the approximate posterior distribution using HMC 
	density(chainBetaBinomialPosteriorHMCDA; xlim=(0.0, 1.0), size=(600,300), legend=:best, width=2, label=L"\hat\theta_{posterior}", title=L"Rate\;\, \hat\theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red, lw=1.5)
end # let

# ╔═╡ e3cc94ae-87d2-4a91-ae59-a69a2083d952
md"
---
###### [Sampler NUTS](https://turinglang.org/dev/docs/library/#Turing.Inference.HMC)
"

# ╔═╡ df90d887-767c-410e-82c0-7f40d478cc7f
chainBetaBinomialPosteriorNUTS = 
	let iterations      = 3000
		nBurnIn         = 1000
		δ               = 0.65
		initialStepSize = 0.3     
		sampler         = NUTS(nBurnIn, δ, init_ϵ=initialStepSize)
		sample(modelBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ e2ffc103-8e2d-45d3-bc15-59bd9428a78d
md"
###### Posterior result:
-  $pdf(\theta_{posterior})$ is single peaked with $\mathbb E(\theta_{posterior}) = 0.599 \approx 0.6$.
"

# ╔═╡ eb266d43-0e31-45b8-acd0-fca6e1edfa40
describe(chainBetaBinomialPosteriorNUTS)

# ╔═╡ 43c3436f-99eb-4390-8274-6899b7a6e878
plot(chainBetaBinomialPosteriorNUTS)

# ╔═╡ 93c0648f-27e5-427a-a1a1-544f1a9fb8e4
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ a8600de4-f34a-4212-9835-85140aef6164
hpd(chainBetaBinomialPosteriorNUTS)

# ╔═╡ 26470b9a-8aaf-45f5-8930-a68050db96f0
let k = 06
	n = 10
	# blue density plot of the approximate posterior distribution using HMC 
	density(chainBetaBinomialPosteriorNUTS; xlim=(0.0, 1.0), size=(600, 300), legend=:best, width=2, label=L"\hat \theta_{posterior}", title=L"Rate\;\; \hat \theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red, lw=1.5)
end # let

# ╔═╡ 2000134e-7c31-425d-8217-322ad4b93851
md"
---
##### 1.2 Inferring a Rate $\theta$ with the *Beta-Bernoulli* Model
(*not* contained in Lee & Wagenmakers, 2013, ch.3.1, p.37-39)
"

# ╔═╡ 2ceb153f-ec2a-4e75-b923-7c124e499090
md"
---
###### 1.2.1 Model Function of *Beta-Bernoulli* Model

- **Prior:** *Beta*
- **Likelihood:** *Bernoulli*
"

# ╔═╡ 7ae488c9-eb4e-472b-b358-7ec3e83d17ff
@model function BetaBernoulli(n; k=missing)                  
	# n = #trials, #experiments
	# k = #successes
	#----------------------------------------------
	# Beta Prior Distribution for Rate Θ
	Θ ~ Beta(1, 1) 
	# Binomial Likelihood
	k ~ Bernoulli(Θ)  # k=1 => sucess/failure in 1 trial
	#----------------------------------------------
end # model BetaBernoulli

# ╔═╡ 8c609fee-a898-42ba-b505-a482ceeae94e
md"
---
###### 1.2.2 Prior Model: $n, k$ are observed contrary to ${data / y}$ and $θ$
where $\mathbf {data / k}$ is the vector of *binary outcomes* of $n$ random experiments. 
"

# ╔═╡ abb96931-03d7-4fa2-972b-ac28521b588b
modelBetaBernoulliPrior =
	let k =  6
		n = 10
		BetaBernoulli(n)
	end # let

# ╔═╡ 437291ee-e579-4952-96a6-b578b7b670dc
chainBetaBernoulliPrior = 
	let iterations = 3000
		sampler    = Prior()
		sample(modelBetaBernoulliPrior, sampler, iterations)
	end # let

# ╔═╡ 930f51fd-608b-4c22-9dd3-0660e922cdaf
md"
---
###### Prior results:
- distributions: $pdf(\theta) = \beta(1, 1)$ and $pmf(k)$ are approximately *uniform* distributions 
- with $mean(\theta)$ = 0.5 and $mean(k) \approx 5.0$.
"

# ╔═╡ a86a25ab-4df3-40e2-955b-872c74370eaa
describe(chainBetaBernoulliPrior)

# ╔═╡ b737d211-d720-4d11-8b28-88b7f906de92
plot(chainBetaBernoulliPrior, bins=2, normalize=true)

# ╔═╡ 1e0f8067-8093-4582-99e2-d0cc0cff34fd
md"
---
###### 1.2.3 Posterior Model: $n, k, \mathbf{data / y} $ are observed contrary to $θ$
where $\mathbf {data (=ks)}$ is the vector of *binary outcomes* of $n$ random experiments. 
"

# ╔═╡ 535916aa-551c-4b4f-97f2-385012b0c03f
ks = data = [1, 0, 1, 0, 1, 0, 0, 1, 1, 1]  # k = 6; n - k = 4

# ╔═╡ 2392db23-324e-4cc3-8d3f-ff992da3adb8
length(data)                           # = n = 10

# ╔═╡ a1b6ae3e-ab1a-4554-8b4c-3781a084c42a
histogram(data, size=(150, 300), bins=1, xlims=(-0.5, +2.0), label=false, normalize=true)

# ╔═╡ 345d09a1-25ef-469b-96cf-6c50a64eee94
modelBetaBernoulliPosterior = 
	let k =  6                         # = number of successes
		n = 10                         # = number of random experiments
		BetaBernoulli(n; k=data)
	end # let

# ╔═╡ cd3a3c82-e97d-4847-95f1-7cb392b1bc49
md"
---
###### [Sampler MH](https://turinglang.org/dev/docs/using-turing/sampler-viz)
"

# ╔═╡ 8653dc8b-e259-4344-abf8-643b9faacd48
chainBetaBernoulliPosteriorMH = 
	let iterations = 3000
		sampler    = MH()
		sample(modelBetaBernoulliPosterior, sampler, 3000)
	end # let

# ╔═╡ 0017b798-9791-43fa-85f9-56051805e2f7
md"
###### Posterior result:
-  $pdf(\theta)$ is single peaked with $mean(\theta) = 0.599 \approx 0.6$.
"

# ╔═╡ dc5a2213-7c32-467b-8652-6fe3f709960e
describe(chainBetaBernoulliPosteriorMH)

# ╔═╡ a3598196-407d-4576-9dab-165b7917c296
plot(chainBetaBernoulliPosteriorMH)

# ╔═╡ bccefcd7-184e-463a-a2f9-2f130bef2bbc
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 374ba091-ca36-4e09-b4f4-2f4e012ac6ec
hpd(chainBetaBinomialPosteriorMH)

# ╔═╡ eb75ff26-ca86-4b68-b171-aaa7cafc4700
let k = 06
	n = 10
	# blue density plot of the approximate posterior distribution using HMC 
	density(chainBetaBernoulliPosteriorMH; xlim=(0.0, 1.0), size=(600, 300),  title=L"Rate\;\, \hat \theta_{posterior}", legend=:best, lw=2, label=L"\hat \theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red)
end # let

# ╔═╡ cb937079-5ace-43e1-8bbe-d5937b5eab89
md"
---
###### [Sampler NUTS](https://turinglang.org/dev/docs/using-turing/sampler-viz)
"

# ╔═╡ a8faf6ce-10c5-41e8-a8ec-76a6179ef70d
chainBetaBernoulliPosteriorNUTS = 
	let iterations      = 3000
		nBurnIn         = 1000
		δ               = 0.65
		initialStepSize = 0.3
		sampler         = NUTS(nBurnIn, δ, init_ϵ=initialStepSize)
		sample(modelBetaBernoulliPosterior, sampler, iterations)
	end # let

# ╔═╡ acdc1984-0c5c-4cdb-963c-66fec11126c7
md"
**Posterior result:** $pdf(\theta)$ is single peaked with $mean(\theta) = 0.599 \approx 0.6$.
"

# ╔═╡ c9bb9d7d-4b2b-4fb9-8b67-68df8302a943
describe(chainBetaBernoulliPosteriorNUTS)

# ╔═╡ d0baf1f4-5525-46de-8b25-53415abdba73
plot(chainBetaBernoulliPosteriorNUTS)

# ╔═╡ 8ae2b37e-fbe0-4600-ac27-84ab6d31ca12
describe(chainBetaBernoulliPosteriorNUTS)

# ╔═╡ bc0fecca-58df-445f-849f-1b4d973be9c4
plot(chainBetaBernoulliPosteriorNUTS)

# ╔═╡ 885a8498-7ce6-4635-8950-61d0b257080b
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 55f1ffaa-d734-4b3b-a93f-b9f98fceeb95
hpd(chainBetaBinomialPosteriorNUTS)

# ╔═╡ 85aa1de8-137f-49d3-ac44-b96294e8a7f1
let k =  6
	n = 10
	# blue density plot of the approximate posterior distribution using HMC 
	density(chainBetaBernoulliPosteriorNUTS; xlim=(0, 1), size=(600, 300), title=L"Rate\;\, \hat \theta_{posterior}", legend=:best, lw=2, label=L"\hat \theta_{posterior}")
	# Visualize the true probability of heads in red.
	vline!([k/n]; label=L"\theta_{posterior}", colour=:red)
end # let

# ╔═╡ 8695b6e8-cff6-4c96-b9cc-035ee4da6d83
md"
---
##### 1.3 Difference between two Rates $\delta = \theta_1 - \theta_2$ of two *Beta-Binomial* Models
([Lee & Wagenmakers, 2013](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B), ch. 3.2, p.39-42)
"

# ╔═╡ 57d5c51d-00c5-4290-a04a-7aeb9ed76679
md"
---
###### 1.3.1 Model Function

BUGS' model script can be transpiled line-by-line from the WinBUGS code (Lee & Wagenmakers, 2013, p. 41) except one important difference. Because $δ$ is a *derived* quantity *not left of* '~' it does not show up itself automatically in plots with $plot(<chain>)$. So we need to compute this *derived* quantity *exterior* the model function. We have to fetch both quantities $\theta1, \theta2$ from the generated MCM chain with extra selection code.

"

# ╔═╡ 24411b77-7bfb-4412-8e44-1aaa2edfbbac
@model function DiffBetaBinomial(n1, n2; k1=missing, k2=missing)
	# Prior Distributions for Rates Θ1, Θ2
	Θ1 ~ Beta(1, 1) 
	Θ2 ~ Beta(1, 1) 
	# Difference between two rates
	δ = Θ1 - Θ2 
	# Likelihoods (= Observed Counts)
	k1 ~ Binomial(n1, Θ1)
	k2 ~ Binomial(n2, Θ2)
	# δ is a derived quantity (= not left of '~'), 
	#   so it has to be computed exterior the model function
end # model

# ╔═╡ a62bafcd-d75b-4ef6-b1c3-146f4832da28
md"
---
###### 1.3.2 Prior Model: $n_1,n_2$ are observed contrary to $k_1,k_2$; $θ$s are latent
  
"

# ╔═╡ 67c33d41-3bf5-4ad5-8498-832182d38e35
modelDiffBetaBinomialPrior = 
	let n1 = n2 = 10
		k1 = 5; k2 = 7
		DiffBetaBinomial(n1, n2)
	end # let

# ╔═╡ abb6df8e-8a36-4325-ad44-185d4620d866
chainDiffBetaBinomialPrior = 
	sample(modelDiffBetaBinomialPrior, Prior(), 2000)

# ╔═╡ 7a205344-a95b-45d9-ad48-145f9f8015aa
md"
###### Prior result:

- with $\mathbb E(\hat\delta)=\mathbb E(\hat\theta_1-\hat\theta_2)=\mathbb E(\hat\theta_1) - \mathbb E(\hat\theta_2)\approx0.5-0.5\approx0.0.$
"

# ╔═╡ 01d1765a-146f-4573-9416-40a4337926fd
describe(chainDiffBetaBinomialPrior)

# ╔═╡ 02ee039c-58b9-46fd-8cb0-56b549bd4c0d
plot(chainDiffBetaBinomialPrior, bins=10)

# ╔═╡ 9fbdae19-39aa-43c6-898e-47b31230ddc9
δPrior  = 
	let Θ1Prior = chainDiffBetaBinomialPrior[:Θ1]
		Θ2Prior = chainDiffBetaBinomialPrior[:Θ2]
		Θ1Prior - Θ2Prior
	end; # let

# ╔═╡ b8845cfa-cb03-45f3-ad7a-aaaf6bbe4435
mean(δPrior)

# ╔═╡ f92a6832-d16b-4617-b048-896c99ebf732
md"
###### Prior result:

- with $\mathbb E(\hat\delta)=\mathbb E(\widehat\theta_1-\hat\theta_2)=\mathbb E(\hat\theta_1) - \mathbb E(\hat\theta_2)\approx 0.5-0.5 \approx0.0.$
"

# ╔═╡ 7f3d3928-9d51-48f0-a829-dd53bbe12105
describe(δPrior)  

# ╔═╡ 24f8ee20-f080-4138-859a-a4a0810ae51a
plot(δPrior)

# ╔═╡ 746578be-d8c6-42b7-879b-d2e0761326b9
let 
	plot(density(δPrior), title=L"Difference\;\; in \;\; Rates\;\;\hat\delta_{prior}=\hat\theta_{1prior}-\hat\theta_{2prior}", size=(600, 300), label=missing, xlabel=L"\hat\delta_{prior}=\hat\theta_{1prior}-\hat\theta_{2prior}")
	vline!([0.0], lw=2, color=:red)
end # let

# ╔═╡ b9a2947e-e0a3-4176-94f3-a38229e9c208
md"
---
###### 1.3.3 Posterior Model: $n_1,n_2,k_1,k_2$ are observed; $k_1,k_2$ are data; $\theta_1, \theta_2$ are *latent*
([Lee & Wagenmakers, 2014, ch.3.2, p.39-42](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B))
"

# ╔═╡ 2f6574e9-c7b0-4142-bccb-70dc97b9f93e
modelDiffBetaBinomialPosterior = 
	let n1 = n2 = 10
		k1 = datum1 = 5
		k2 = datum2 = 7
		DiffBetaBinomial(n1, n2, k1=datum1, k2=datum2)
	end # let

# ╔═╡ 1d3c754f-83ee-4e24-b3f0-1cbb74264f61
md"
---
###### [Sampler NUTS](https://turinglang.org/dev/docs/using-turing/sampler-viz)
"

# ╔═╡ 9c5f2833-39d5-4d8e-97f2-96a514d9cd53
chainDiffBetaBinomialPosteriorNUTS = 
	let iterations      = 3000
		nBurnIn         = 1000
		δ               = 0.65
		initialStepSize = 0.3
		sampler         = NUTS(nBurnIn, δ, init_ϵ=initialStepSize)
		sample(modelDiffBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ 8cfd8e19-3792-4a14-98ba-a8a5c0c15d8e
describe(chainDiffBetaBinomialPosteriorNUTS)

# ╔═╡ acf76b7f-0ea5-4abb-9e46-5da914470ba7
plot(chainDiffBetaBinomialPosteriorNUTS)

# ╔═╡ 854682c4-d17d-4629-bdba-476957d2d377
md"
###### Posterior result:

- with WinBUGS: $\mathbb E(\hat\delta)\approx-0.17$ and the 95% credible interval is approximately $[-0.52, 0.21]$ ([Lee & Wagenmakers, 2014, ch.3.2, p.42](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B)).
"

# ╔═╡ a4884c1f-db4a-4439-a958-dc01e76c6c4d
δPosterior  = 
	let Θ1Posterior = chainDiffBetaBinomialPosteriorNUTS[:Θ1]
		Θ2Posterior = chainDiffBetaBinomialPosteriorNUTS[:Θ2]
		Θ1Posterior - Θ2Posterior
	end; # let

# ╔═╡ 8c78f211-a32f-4304-860a-68a1ee34ad2a
mean(δPosterior)      # ==> -0.17 --> :) c.f. Lee & Wagenmakers, 2014, ch.3.2, p.42

# ╔═╡ 3b879379-3a93-4697-a6e5-551e4ef18e0c
describe(δPosterior)                   # c.f. Lee & Wagenmakers, 2014, ch.3.2, p.42

# ╔═╡ ecd5963a-c919-48de-b25b-21ccca123418
let deltaPlot = 
	histogram(δPosterior, label=L"\hat δ_{posterior} \leftarrow (\theta_1 - \theta_2)", bottom_margin=10Plots.mm, alpha=0.75, title=L"Difference \;\;\hat δ_{posterior} \leftarrow (\theta_{1posterior} - \theta_{2posterior})", normalize=true)
	densityPlot = 
		density!(δPosterior, label=L"\hat δ_{posterior} \leftarrow (\theta_1 - \theta_2)", lw=5)
	chainPlot = 
		plot(δPosterior, size=(1000, 600))
	plot(chainPlot, densityPlot, size=(1200, 300), left_margin=10Plots.mm, bottom_margin=10Plots.mm, alpha=0.75, normalize=true)
end # let

# ╔═╡ cca0e064-6013-4229-8f93-159bcc264682
let
	deltaPlot = 
		histogram(δPosterior, size=(600, 300), label=L"\hat δ_{posterior} \leftarrow (\theta_1 - \theta_2)", bottom_margin=10Plots.mm, alpha=0.75, title=L"Difference \;\;\hat δ_{posterior} \leftarrow (\theta_{1posterior} - \theta_{2posterior})", normalize=true)
	density!(δPosterior, label=L"\hat δ_{posterior} \leftarrow (\theta_1 - \theta_2)", lw=5)
	vline!([mean(δPosterior)]; label=L"δ_{posterior}", lw=3, colour=:red)
	xlabel!(L"Difference \;\;\hat δ_{posterior} \leftarrow (\theta_{1posterior} - \theta_{2posterior})")
	ylabel!("Posterior Density")
end # let

# ╔═╡ 6970b91d-530e-44a4-b6da-9982f5100ae0
md"
---
##### 1.4 Inferring a Common Rate $\delta = \theta_1 = \theta_2$ with two *Binomial* Likelihoods
([Lee & Wagenmakers, 2013, ch. 3.3, p.43-45](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B))
"

# ╔═╡ 60e66b48-57ae-4df8-a066-f64f7930b1f8
md"
---
###### 1.4.1 Model Function

Here line-by-line transpilation from WinBUGS to TURING.jl is possible (cf. Lee & Wagenmakers, 2013, p.43f)
"

# ╔═╡ 442ae531-96a1-42a7-a02a-fa949986bcd1
@model function CommonBetaBinomial(n1, n2; k1=missing, k2=missing)
	# Prior Distributions for Common Rate Θ 
	Θ ~ Beta(1, 1) 
	# Binomial Likelihoods (= Observed Counts)
	k1 ~ Binomial(n1, Θ)
	k2 ~ Binomial(n2, Θ)
	Θ
end # model

# ╔═╡ 907df583-2f40-40cb-bf73-06f8f98a17a2
md"
---
###### 1.4.2 Prior Model: $n_1,n_2$ are *observed* contrary to $k_1,k_2$; $θ$ is *latent*
  
"

# ╔═╡ 7cccd9ac-0011-4614-9712-ba1fbd12f136
modelCommonBetaBinomialPrior = 
	let k1 = 5
		k2 = 7
		n1 = n2 = 10
		CommonBetaBinomial(n1, n2)
	end # let

# ╔═╡ d1853cca-7276-42ed-9a06-c9c46d059881
chainCommonBetaBinomialPrior = 
	let iterations = 4000
		sampler    = Prior()
		sample(modelCommonBetaBinomialPrior, sampler, iterations)
	end # let

# ╔═╡ 825f717a-c110-4b22-aa7e-342ee8479113
describe(chainCommonBetaBinomialPrior)

# ╔═╡ 3fc5d9c0-6d96-4f49-8302-2ca574bf9699
plot(chainCommonBetaBinomialPrior, bins=10)

# ╔═╡ 8702025d-00ba-4d10-83a3-47c44f0a272f
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ 4ea11602-83c4-4bdd-9525-9a6698183397
hpd(chainCommonBetaBinomialPrior)

# ╔═╡ 32e0a393-bd3e-40f0-9244-d85cfef14560
let k =  6
	n = 10
	modelBetaBinomialPrior = BetaBinomial(n)
	#-----------------------------------------------------------------------
	θPrior = 
	let parms = 
			MCMCChains.get_sections(chainCommonBetaBinomialPrior, :parameters) 
		generated_quantities(modelCommonBetaBinomialPrior, parms)
	end # let
	# blue density plot of the prior
	density(θPrior; xlim=(-0.1, 1.1), size=(600, 300),egend=:best, lw=2, label=L"\hat\theta_{prior}", title=L"Rate\;\, \hat\theta_{prior}", xlabel=L"\hat θ", ylabel=L"density\; f(\hat θ)")
	# Visualize the true probability of heads in red
	vline!([k/n]; label=L"\theta_{prior}", colour=:red, lw=1.5)
end # let

# ╔═╡ 06db4af2-7aa0-4f44-bfe1-cab4d11c7f45
md"
---
###### 1.4.3 Posterior Model: $n_1,n_2,k_1,k_2$ are *observed*; $θ$ is *latent*
([Lee & Wagenmakers, 2014, ch.3.3, p.43-45](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B))
"

# ╔═╡ 24387f02-4b28-4cc0-9213-a501437bd7ee
modelCommonBetaBinomialPosterior = 
	let k1 = datum1 = 5
		k2 = datum2 = 7
		n1 = n2 = 10
		CommonBetaBinomial(n1, n2, k1=datum1, k2=datum2)
	end # let

# ╔═╡ 1c1ed766-c9ad-433b-8edc-d2759c9384e7
md"
---
###### [Sampler MH](https://turinglang.org/dev/docs/using-turing/sampler-viz)
"

# ╔═╡ cc96c101-aa78-4b24-84e5-3f4917a89131
chainCommonBetaBinomialPosteriorMH = 
	let iterations = 5000
		sampler    = MH()
		sample(modelCommonBetaBinomialPosterior, sampler, iterations)
	end # let

# ╔═╡ 119efa48-fd32-4420-b57a-df822abc5ea0
md"
###### Posterior result:

- with WinBUGS: $\mathbb E(\hat\delta)\approx 0.6$ (Lee & Wagenmakers, 2014, ch.3.3, fig. 3.7, p.44).
"

# ╔═╡ 83f043f6-bb14-415c-9a0f-38ba2ff7a423
describe(chainCommonBetaBinomialPosteriorMH)  # ==> Θ == 0.6 --> :)

# ╔═╡ 8a6d5609-a51c-4d0a-83ac-5a33b41ca66a
plot(chainCommonBetaBinomialPosteriorMH)  # ==> Θ == 0.6 --> :)

# ╔═╡ 37839eb8-c914-4314-a11b-1eb65e41ab06
md"
---
###### Highest (1-α) Posterior Density Interval
"

# ╔═╡ d3c5d38b-88af-4edd-b7b2-bc197dfcf005
hpd(chainCommonBetaBinomialPosteriorMH)

# ╔═╡ cebbfd86-428e-4ca2-ac2a-08615a28527d
let θPosterior = 
	let parms = 
			MCMCChains.get_sections(chainCommonBetaBinomialPosteriorMH, :parameters)
		posteriorParms = 
			generated_quantities(modelCommonBetaBinomialPosterior, parms) 
		posteriorParms[:]
	end # let
	# blue density plot of the approximate posterior distribution using MH 
	density(θPosterior; xlim=(0, 1), size=(600, 300), title=L"Rate\;\, \hat\theta_{posterior}", legend=:best, lw=2, label=L"\hat \theta_{posterior}", xlabel=L"\hat \theta_{posterior}", ylabel=L"f(\hat \theta_{posterior})")
	# Visualize the true probability of heads in red.
	vline!([mean(θPosterior)], label=L"\theta_{posterior}", colour=:red)
end # let

# ╔═╡ 4e976941-48c4-478b-8d5a-b3cd468b6076
md"
---
##### 1.5 Prior and Posterior Prediction
([Lee & Wagenmakers, 2013, ch. 3.4, p.45-47](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B))

WinBUGS is in contrast to Turing.jl a *declarative* Bayesian modeling language. So the order of declarations is irrelevant. This is not true for Turing.jl. Here we try after some reordering a close line-by-line transpilation (below in $function\;\; priorPosteriorPredictive$) of Lee & Wagenmaker(L&W)'s WinBUGS script. 

This leads only for some samplers to satisfying results so that L&W's plots in Fig. 3.9 can be reconstructed. This figure consists of two plots. One plot displays prior and posterior distributions of $\theta$, the other prior and posterior (datat) predictions. These are counterfactual data distributions generated by likelihoods driven by the prior and posterior $\theta$.
"

# ╔═╡ 3e910200-0ec6-4455-8095-ac5d0d642ed5
md"
---
###### Model Function
"

# ╔═╡ 9ddc224e-496b-4205-97df-07377bcc146f
@model function priorPosteriorPredictive(n) # without 'k' as parameter
	#----------------------------------------------------
	# prior on rate θ
	θ ~ Beta(1, 1)	
	#----------------------------------------------------
	# likelihood of observed data
	k ~ Binomial(n, θ)	
	#----------------------------------------------------
	# prior predictive
	θPriorPred ~ Beta(1, 1)	
	kPriorPred ~ Binomial(n, θPriorPred)
	#----------------------------------------------------
	# posterior predictive
	kPostPred  ~ Binomial(n, θ)
	#----------------------------------------------------
end # function priorPosteriorPredictive

# ╔═╡ 8f78ebf4-ed0d-4607-b63f-27d10c11d99a
md"
---
###### Prior-Predictive Model
"

# ╔═╡ ef2927b1-7ff5-44ac-8381-ec784896bb61
modelPriorPredictive =
	let k =  1                          # not used here
		n = 15
		priorPosteriorPredictive(n)                        
	end # let

# ╔═╡ 6936ff5e-a0b9-47fa-bbdc-c6aa8a84fdde
chainPriorPredictive = 
	let iterations = 3000
		sampler    = Prior()
		sample(modelPriorPredictive, sampler, iterations)
	end # let

# ╔═╡ 007f26ae-0fd9-464f-a2ae-274480258dfa
describe(chainPriorPredictive)

# ╔═╡ 752324ab-8acd-4645-883b-34baf4060dd6
plot(chainPriorPredictive, normalize=true)

# ╔═╡ fc79cd60-3c60-4186-9758-eeb56e95ea9a
md"
---
###### Posterior Predictive Model Function
"

# ╔═╡ 38b47426-1020-48d5-91db-ce57c456bd5c
modelPosteriorPredictive =
	let k     =  1
		datum =  k
		n     = 15
		# priorPosteriorPredictive(n)             # prior predictive without datum
		priorPosteriorPredictive(n) | (; k=datum) # posterior predictive incl. datum
	end # let 

# ╔═╡ aa409459-3526-4849-82ba-02293118953a
md"
---
###### Sampler: [Particle Gibbs (PG)](https://turinglang.org/dev/docs/using-turing/sampler-viz)

Sampler PG expects that there are *no* keyword parameters in the model function. So we have to use the *condition bar* $'|'$ when computing the posterior distribution.
The advice for using *PG* was given by [Xiang, Xd (Xianda, 2023)](https://github.com/TuringLang/Turing.jl/issues/2148).
"

# ╔═╡ bfb3fba9-2617-4615-a4d0-39c117a75c96
chainPosteriorPredictive = 
	let iterations = 3000
		#=
		nBurnIn    = 1000
		δ          = 0.65
		init_ϵ     = 0.3
		sampler    = NUTS(nBurnIn, δ, init_ϵ=init_ϵ)   # NUTS fails
		=#
		nParticles = 10
		sampler    = PG(nParticles)                    # success with PG
		sample(modelPosteriorPredictive, sampler, iterations)
	end # let

# ╔═╡ 8815a023-aa00-421c-bb6b-724df77aed4a
describe(chainPosteriorPredictive)

# ╔═╡ a121488d-d71d-4907-b9d3-7f49eabe2840
plot(chainPosteriorPredictive, normalize=true, bins=10)

# ╔═╡ 180c8256-1f89-422b-9391-b7d6d1bf981f
md"
---
###### Reconstruction of Lee & Wagenmakers' Fig. 3.9 
(Lee & Wagenmakers, 2013, ch. 3.4, Fig. 3.9, p.46)
"

# ╔═╡ daf5c968-796e-4079-8713-88dfc93fd00b
begin
	θPrior     = chainPriorPredictive[:θ]
	θPosterior = chainPosteriorPredictive[:θ]
	plot(density(θPrior, label=L"\theta_{prior}", size=(600, 300)), ylimit=(0, 7), title=L"\theta_{prior&posterior}")
	plot!(density!(θPosterior, label=L"\theta_{posterior}"))
end # begin

# ╔═╡ 1767adc8-5496-4e18-8be2-ec0342f9c4da
begin
	kPriorPredictive     = chainPriorPredictive[:kPriorPred]
	kPosteriorPredictive = chainPosteriorPredictive[:kPostPred]
	plot(histogram(kPriorPredictive, normalize=true, label=L"k_{priorPredictive}", size=(600, 300), ylimit=(0, 0.6)), title=L"k_{priorPredictive&posteriorPredictive}")
	plot!(histogram!(kPosteriorPredictive, normalize=true, label=L"k_{posteriorPredictive}"))
end # begin

# ╔═╡ 171970d1-2c37-46de-8771-77f32d3a7308
md"
---
###### Sampler GIBBS
The advice to use this sampler was provided by [Xiang, Xi (Xianda, 2023)](https://github.com/TuringLang/Turing.jl/issues/2148).
"

# ╔═╡ 63941183-4d6c-42d5-a334-7e6bdd7e036a
@model function priorPosteriorPredictive2(n)
   θ ~ Beta(1, 1)
   k ~ Binomial(n, θ)
   θPriorPred ~ Beta(1, 1)
   kPriorPred ~ Binomial(n, θPriorPred)
   kPostPred  ~ Binomial(n, θ)
   θPriorPred, kPriorPred, kPostPred  # last expression will be returned
end # function priorPosteriorPredictive2

# ╔═╡ 093718f0-2299-4c2c-b5ef-8b1c06d0d09b
modelPriorPosteriorPredictive2 = 
	let k     = 1
		datum = k
		priorPosteriorPredictive2(15) | (; k=datum) # creating the model
	end # let

# ╔═╡ b2beba89-e464-48f5-93f7-e1432f1e7f54
chainPriorPosteriorPredictive2 = 
	let iterations = 3000
		sampler1 = HMC(0.05, 10, :θ)             # HMC for continuous variable
		sampler2 = NUTS(-1, 0.65, :θPriorPred)   # NUTS for continuous variable
		sampler3 = PG(100, :k, :kPriorPred, :kPostPred) # for discrete variables
		# use HMC for `θ`, NUTS for `θPriorPred`, and PG for the rest.
		sample(modelPriorPosteriorPredictive2, Gibbs(sampler1, sampler2, sampler3), iterations) 
	end # let

# ╔═╡ ed3328b6-f0cb-440c-a116-68dcb754930b
describe(chainPriorPosteriorPredictive2)

# ╔═╡ 565448e8-6d48-4946-b65d-be6a9b8247b0
plot(chainPriorPosteriorPredictive2)

# ╔═╡ ccb1f9a0-09de-4697-93b0-943e7fd6cdcf
md"
---
###### Summary
Function $priorPosteriorPredictive$ is designed to be used *both* for generating *prior predictives* and *posterior predictives*. 

This is a success under two conditions. *First*, keyword parameters in the model function for introducing conditional data have to be avoided. Instead we have to use the condition bar '|'. *Second*, because some samplers (like NUTS) fail when sampling has to be done *both* for continuous and discrete variables we have to sample with competent samplers (like 'PG'). This advice was provided by Xiang, Xi (2023).

"

# ╔═╡ 39b0166b-6568-4482-8f2e-c44082c2284c
md"
---
##### 1.5 Posterior Prediction
(cf. Lee & Wagenmakers, 2013, ch.3.5, p.47-49)

---
###### Model Function
"

# ╔═╡ 2a206181-cbcd-4a76-8d10-c151a911ddb8
@model function CommonBetaBinomialWithPostPred(n1, n2)
	#---------------------------------------------------------
	# Prior Distributions for Common Rate Θ 
	Θ ~ Beta(1, 1) 
	#---------------------------------------------------------
	# Binomial Likelihoods (= Observed Counts)
	k1 ~ Binomial(n1, Θ)
	k2 ~ Binomial(n2, Θ)
	#---------------------------------------------------------
	# Posterior Predictives
	postPred1 ~ Binomial(n1, Θ)
	postPred2 ~ Binomial(n2, Θ)
	#---------------------------------------------------------
end # model function CommonBetaBinomialWithPostPred

# ╔═╡ a8039911-1ee5-40ff-ad2d-e38e3c8b5c39
md"
---
###### Posterior Predictive Model
"

# ╔═╡ e71c5a7b-e724-46e2-bb62-11bfa33b6e93
modelPosteriorPredictives =
	let k1  =  0
		k2  = 10
		n1  = n2 = 10
		# posterior predictive incl. datum
		CommonBetaBinomialWithPostPred(n1, n2) | (; k1=k1, k2=k2) 
	end # let 

# ╔═╡ 53283fe4-d7d5-4d04-8d12-df9ae05ae326
chainPosteriorPredictives = 
	let iterations = 3000
		nParticles = 10
		sampler    = PG(nParticles)                    # success with PG
		sample(modelPosteriorPredictives, sampler, iterations)
	end # let

# ╔═╡ c0406b45-2fe2-47ee-9fb1-fe6d8b4036a5
md"
###### Posterior Results
Here we display the *posterior* distribution of $\theta_{posterior}$ (cf. Lee & Wagenmakers, 2013, Fig.3.11, left panel), the *1d-posterior* distributions and the *2d-posterior predictive* distribution ((cf. Lee & Wagenmakers, 2013, Fig.3.11, right panel), based on $k_1=0$ and $k_2=10$ successes out of $n=10$ observations.

"

# ╔═╡ 734c94e9-95e5-4240-bb3a-b9af1826e51d
describe(chainPosteriorPredictives)

# ╔═╡ cb93d964-7fa9-4520-b7a1-3772c5872447
plot(chainPosteriorPredictives)

# ╔═╡ 8ac85301-6bb5-4d06-aff0-1eedc5353d6d
let pp1 = chainPosteriorPredictives[:postPred1]
	pp2 = chainPosteriorPredictives[:postPred2]
	k1s =  0
	k2s = 10
	marginalhist(pp1, pp2, size=(600, 500), xlim=(-1, 12), ylim=(-1, 12), bins=10, xlabel=L"Success\;\; Count\;\; k_1", ylabel=L"Success\;\; Count\;\; k_2")
	marginalhist!([0], [10], size=(600, 500), xlim=(-1, 12), ylim=(-1, 12), bins=10, color=:red)
end # let

# ╔═╡ d56230ef-54e5-4867-b5a2-663cc5e384fd
md"
The *2d-posterior predictive* distribution (cf. Lee & Wagenmakers, 2013, Fig.3.11, right panel) as a *heat map*, based on $k_1=0$ and $k_2=10$ successes out of $n=10$ observations.The actual data with $k_1=0$ and $k_2=10$ are marked in the above figure by a red square.
"

# ╔═╡ 1afaa80d-0f11-476f-8f1c-799c36268c59
md"
---
##### 1.6  Joint Distributions
###### $k[i] = n_i \le n_{max}$ Surveys Returned from $m$ Bundles of $n \le n_{max}$ Items
(cf. Lee & Wagenmakers, 2013, ch.3.6, p.49-53)

---
###### Model Function
(cf. Lee & Wagenmakers, 2013, Fig. 3.12, p.51)

-  $nmax$ = *maximal number* $n_i \le n_{max}$ of items in bundles
-  $m$ = *number* of $i=1,...,m$ bundles or helpers
"

# ╔═╡ 4cb28df6-0945-446e-a042-5391b958e426
@model function jointDistributions(nmax, m) 
	#---------------------------------------------------------
	onesS   = ones(Float64, nmax)
	zeros_m = zeros(Int64, m)
	k       = zeros(Int64, m)
	ni      = zeros(Int64, nmax)
	#---------------------------------------------------------
	# Prior Distributions for Rates Θ and p[i] = 1/nmax
	Θ  ~ Beta(1, 1) 
	pi = onesS ./nmax
	#---------------------------------------------------------
	# Categorical Likelihoods (= Observed Counts)
	ni ~ Categorical(pi)                      # n = 1,...,nmax
	#---------------------------------------------------------
	# Binomial Likelihoods (= Observed Counts)
	for i in 1:m
		k[i] ~ Binomial(ni, Θ)
	end # for
	#---------------------------------------------------------
end # model function jointDistributions

# ╔═╡ af0d0a5e-64cd-4f58-b2ba-ccbd45642d99
modelPosteriorJointDistributions =
	let ks   =  [16, 18, 22, 25, 27]
        m    = 5
		nmax = 500
		# posterior predictive incl. data
		jointDistributions(nmax, m) | (; k=ks) 
	end # let 

# ╔═╡ 44925d7b-667b-4fc1-b942-d30005503e85
chainPosteriorPredictives2 = 
	let iterations = 3000
		nParticles = 20
		sampler    = PG(nParticles)                    # success with PG
		sample(modelPosteriorJointDistributions, sampler, iterations)
	end # let

# ╔═╡ cc990d60-05c6-4033-aaf6-15993966040b
describe(chainPosteriorPredictives2)

# ╔═╡ 4f5ee761-f254-4a15-85a7-8a085bb0f26a
plot(chainPosteriorPredictives2)

# ╔═╡ 7221a4f4-2127-4b6e-89bb-531d44ce3af8
function posteriorStatistic(chainPosteriorPredictives; statistic=maximum, eps=0.10)
#	(statisticLogEvid, statisticθP, statisticNiP) =          # MAP(), MLE(), E()
		let θPost          = chainPosteriorPredictives[:Θ]
	    	niPost         = chainPosteriorPredictives[:ni]
			logEvidences   = chainPosteriorPredictives[:logevidence]
			statisticLogEvidence = statistic(logEvidences[:,1])
			logEθniP       = 
				map((logEvidence, θP, niP) -> 
					(logEvidence, θP, niP), logEvidences, θPost, niPost)
				filter(lthni -> 
					let (l,th,ni) = lthni
						if (statistic == maximum) || (statistic == mode)
							l === statisticLogEvidence
						else
							abs(l - statisticLogEvidence) <= eps
						end # if
					end, logEθniP)[1]
		end # let
end # function posteriorStatistic

# ╔═╡ 28bfbb06-8834-4b31-a26c-34bed249708b
(mapLogEvid, mapθP, mapNiP) =                         # MAP(), ML()
	posteriorStatistic(chainPosteriorPredictives2)

# ╔═╡ 747d8f68-6560-4d9c-8ee5-0f0143567773
(modeLogEvid, modeθP, modeNiP) =                      # Mode()
	posteriorStatistic(chainPosteriorPredictives2; statistic=mode)

# ╔═╡ 4b0921c9-b549-4edc-8486-992df4f2baa2
(expectedLogEvid, expectedθP, expectedNiP) =
	posteriorStatistic(chainPosteriorPredictives2; statistic=mean, eps=.1036)

# ╔═╡ d5d5e777-523f-4802-9428-7bcb97eef394
let θPost     = chainPosteriorPredictives2[:Θ]
	niPost    = chainPosteriorPredictives2[:ni]
	expectedθ = expectedθP
	expectedN = expectedNiP # round(Int, mean(niPost))
	#--------------------------------------------------------------------------------
	scatter(niPost, θPost, size=(600, 500), ylim=(0, 1), xlim=(1,500), bins=50, xlabel=L"Size\;\; of\;\; Survey\;\; Returned", ylabel=L"Rate\;\;\theta \;\;of\;\;Return", markersize=4, label="Posterior Sample", title="Joint Post. Distrib. of Return Rate θ and Survey Size n")
	#--------------------------------------------------------------------------------
	scatter!([mapNiP], [mapθP], size=(600, 500), ylim=(0, 1), xlim=(1, 500), bins=50, color=:yellow, markershape=:square, markersize=6, label=L"MAP(\theta_{posterior}, ni_{posterior})")
	#--------------------------------------------------------------------------------
	scatter!([modeNiP], [modeθP], size=(600, 500), ylim=(0, 1), xlim=(1, 500), bins=50, color=:red, markershape=:diamond, markersize=7, label=L"Mode(\theta_{posterior}, ni_{posterior})")
	#--------------------------------------------------------------------------------
	scatter!([expectedN], [expectedθ], size=(600, 500), ylim=(0, 1), xlim=(1, 500), bins=50, color=:red, markershape=:star5, markersize=11, label=L"\mathbb {E(\theta_{posterior}, ni_{posterior})}")
	#--------------------------------------------------------------------------------
end # let

# ╔═╡ 07bff31d-da31-49f3-8439-fd99effa00f6
md"
This graphic is a reconstruction of Lee & Wagenmakers' Fig. 3.13 (L&W, 2013, p.52). From their WinBugs script on p.51 it is not clear how the various posterior statistics were computed. This is made explicit here with our $function \;\;posteriorStatistic$.
"

# ╔═╡ 83513428-dbd3-44d5-a4d6-cc722d0513fa
md"
---
##### References

- **Lee, M.D. & Wagenmakers, E.J.**; *[Bayesian Cognitive Modeling](https://www.cambridge.org/core/books/bayesian-cognitive-modeling/B477C799F1DB4EBB06F4EBAFBFD2C28B)*, Cambridge, UK: Cambridge University Press, 2013

- **Sun, (Xianda), H.**, *Comment to [Transpilation of pure WinBUGS code when reimplementing Prior and Posterior Prediction](https://github.com/TuringLang/Turing.jl/issues/2148)*, last visit 2023/12/21

- **Tarek, M., Xu, K., Trapp, M., Ge, H. & Gharamani, Z.**; *[DynamicPPL: Stan-like Speed for Dynamic Probabilistic Models](https://arxiv.org/ftp/arxiv/papers/2002/2002.02702.pdf)*, 2020, arXiv preprint arXiv:2002.02702, 2020, [arxiv.org](https://www.researchgate.net/profile/Mohamed-Tarek-18/publication/339138813_DynamicPPL_Stan-like_Speed_for_Dynamic_Probabilistic_Models/links/615160b2f8c9c51a8af665eb/DynamicPPL-Stan-like-Speed-for-Dynamic-Probabilistic-Models.pdf); last visit 2023/11/27

"

# ╔═╡ 4a1847fc-b9d0-431d-90de-d53cda117754
md"
====================================================================================

This is a **draft** under the Attribution-NonCommercial-ShareAlike 4.0 International **(CC BY-NC-SA 4.0)** license. Comments, suggestions for improvement and bug reports are welcome: **claus.moebus(@)uol.de**

====================================================================================
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
MCMCChains = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
Turing = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"

[compat]
DataFrames = "~1.6.1"
LaTeXStrings = "~1.3.1"
MCMCChains = "~6.0.4"
Optim = "~1.7.8"
StatsBase = "~0.34.2"
StatsPlots = "~0.15.6"
Turing = "~0.29.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "48f38ac744a90d78383e34ae3f7df1112b1d026d"

[[deps.ADTypes]]
git-tree-sha1 = "332e5d7baeff8497b923b730b994fa480601efc7"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "0.2.5"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractMCMC]]
deps = ["BangBang", "ConsoleProgressMonitor", "Distributed", "LogDensityProblems", "Logging", "LoggingExtras", "ProgressLogging", "Random", "StatsBase", "TerminalLoggers", "Transducers"]
git-tree-sha1 = "87e63dcb990029346b091b170252f3c416568afc"
uuid = "80f14c24-f653-4e6a-9b94-39d6b0f70001"
version = "4.4.2"

[[deps.AbstractPPL]]
deps = ["AbstractMCMC", "DensityInterface", "Random", "Setfield", "SparseArrays"]
git-tree-sha1 = "caa9b62583577b0d6b222f11f54aa29fabbdb5ca"
uuid = "7a57a42e-76ec-4ea3-a279-07e840d6d9cf"
version = "0.6.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "faa260e4cb5aba097a73fab382dd4b5819d8ec8c"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.4"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "LinearAlgebra", "MacroTools", "Test"]
git-tree-sha1 = "a7055b939deae2455aa8a67491e034f735dd08d3"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.33"

    [deps.Accessors.extensions]
    AccessorsAxisKeysExt = "AxisKeys"
    AccessorsIntervalSetsExt = "IntervalSets"
    AccessorsStaticArraysExt = "StaticArrays"
    AccessorsStructArraysExt = "StructArrays"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    Requires = "ae029012-a4dd-5104-9daa-d747884805df"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cde29ddf7e5726c9fb511f340244ea3481267608"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AdvancedHMC]]
deps = ["AbstractMCMC", "ArgCheck", "DocStringExtensions", "InplaceOps", "LinearAlgebra", "LogDensityProblems", "LogDensityProblemsAD", "ProgressMeter", "Random", "Requires", "Setfield", "SimpleUnPack", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "acbe805c3078ba0057bb56985248bd66bce016b1"
uuid = "0bf59076-c3b1-5ca4-86bd-e02cd72cde3d"
version = "0.5.5"

    [deps.AdvancedHMC.extensions]
    AdvancedHMCCUDAExt = "CUDA"
    AdvancedHMCMCMCChainsExt = "MCMCChains"
    AdvancedHMCOrdinaryDiffEqExt = "OrdinaryDiffEq"

    [deps.AdvancedHMC.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    MCMCChains = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
    OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"

[[deps.AdvancedMH]]
deps = ["AbstractMCMC", "Distributions", "FillArrays", "LinearAlgebra", "LogDensityProblems", "Random", "Requires"]
git-tree-sha1 = "b2a1602952739e589cf5e2daff1274a49f22c9a4"
uuid = "5b7e9947-ddc0-4b3f-9b55-0d8042f74170"
version = "0.7.5"
weakdeps = ["DiffResults", "ForwardDiff", "MCMCChains", "StructArrays"]

    [deps.AdvancedMH.extensions]
    AdvancedMHForwardDiffExt = ["DiffResults", "ForwardDiff"]
    AdvancedMHMCMCChainsExt = "MCMCChains"
    AdvancedMHStructArraysExt = "StructArrays"

[[deps.AdvancedPS]]
deps = ["AbstractMCMC", "Distributions", "Libtask", "Random", "Random123", "StatsFuns"]
git-tree-sha1 = "4d73400b3583147b1b639794696c78202a226584"
uuid = "576499cb-2369-40b2-a588-c64705576edc"
version = "0.4.3"

[[deps.AdvancedVI]]
deps = ["Bijectors", "Distributions", "DistributionsAD", "DocStringExtensions", "ForwardDiff", "LinearAlgebra", "ProgressMeter", "Random", "Requires", "StatsBase", "StatsFuns", "Tracker"]
git-tree-sha1 = "1f919a9c59cf3dfc68b64c22c453a2e356fca473"
uuid = "b5ca4192-6429-45e5-a2d9-87aec30a685c"
version = "0.2.4"

[[deps.ArgCheck]]
git-tree-sha1 = "a3a402a35a2f7e0b87828ccabbd5ebfbebe356b4"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "9b9b347613394885fd1c8c7729bfc60528faa436"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.4"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "247efbccf92448be332d154d6ca56b9fcdd93c31"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.6.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Atomix]]
deps = ["UnsafeAtomics"]
git-tree-sha1 = "c06a868224ecba914baa6942988e2f2aade419be"
uuid = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
version = "0.1.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.BangBang]]
deps = ["Compat", "ConstructionBase", "InitialValues", "LinearAlgebra", "Requires", "Setfield", "Tables"]
git-tree-sha1 = "e28912ce94077686443433c2800104b061a827ed"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.3.39"

    [deps.BangBang.extensions]
    BangBangChainRulesCoreExt = "ChainRulesCore"
    BangBangDataFramesExt = "DataFrames"
    BangBangStaticArraysExt = "StaticArrays"
    BangBangStructArraysExt = "StructArrays"
    BangBangTypedTablesExt = "TypedTables"

    [deps.BangBang.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    TypedTables = "9d95f2ec-7b3d-5a63-8d20-e2491e220bb9"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[deps.Bijectors]]
deps = ["ArgCheck", "ChainRules", "ChainRulesCore", "ChangesOfVariables", "Compat", "Distributions", "Functors", "InverseFunctions", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "MappedArrays", "Random", "Reexport", "Requires", "Roots", "SparseArrays", "Statistics"]
git-tree-sha1 = "199dc2c4151db557549a0ad8888ce1a60337ff42"
uuid = "76274a88-744f-5084-9051-94815aaf08c4"
version = "0.13.8"

    [deps.Bijectors.extensions]
    BijectorsDistributionsADExt = "DistributionsAD"
    BijectorsForwardDiffExt = "ForwardDiff"
    BijectorsLazyArraysExt = "LazyArrays"
    BijectorsReverseDiffExt = "ReverseDiff"
    BijectorsTrackerExt = "Tracker"
    BijectorsZygoteExt = "Zygote"

    [deps.Bijectors.weakdeps]
    DistributionsAD = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.BitFlags]]
git-tree-sha1 = "2dc09997850d68179b69dafb58ae806167a32b1b"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.8"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRules]]
deps = ["Adapt", "ChainRulesCore", "Compat", "Distributed", "GPUArraysCore", "IrrationalConstants", "LinearAlgebra", "Random", "RealDot", "SparseArrays", "SparseInverseSubset", "Statistics", "StructArrays", "SuiteSparse"]
git-tree-sha1 = "006cc7170be3e0fa02ccac6d4164a1eee1fc8c27"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.58.0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "e0af648f0692ec1691b5d094b8724ba1346281cf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.18.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.ChangesOfVariables]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "2fba81a302a7be671aefe194f0525ef231104e7f"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.8"
weakdeps = ["InverseFunctions"]

    [deps.ChangesOfVariables.extensions]
    ChangesOfVariablesInverseFunctionsExt = "InverseFunctions"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "05f9816a77231b07e634ab8715ba50e5249d6f76"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "886826d76ea9e72b35fcd000e535588f7b60f21d"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+1"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "8cfa272e8bdedfa88b6aefbbca7c19f1befac519"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.3.0"

[[deps.ConsoleProgressMonitor]]
deps = ["Logging", "ProgressMeter"]
git-tree-sha1 = "3ab7b2136722890b9af903859afcf457fa3059e8"
uuid = "88cd18e8-d9cc-4ea6-8889-5259c0d15c8b"
version = "0.1.2"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c53fc348ca4d40d7b371e71fd52251839080cbc9"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.4"
weakdeps = ["IntervalSets", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DefineSingletons]]
git-tree-sha1 = "0fba8b706d0178b4dc7fd44a96a92382c9065c2c"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.2"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "66c4c81f259586e8f002eacebc177e1fb06363b0"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.11"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "9242eec9b7e2e14f9952e8ea1c7e31a50501d587"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.104"
weakdeps = ["ChainRulesCore", "DensityInterface", "Test"]

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

[[deps.DistributionsAD]]
deps = ["Adapt", "ChainRules", "ChainRulesCore", "Compat", "Distributions", "FillArrays", "LinearAlgebra", "PDMats", "Random", "Requires", "SpecialFunctions", "StaticArrays", "StatsFuns", "ZygoteRules"]
git-tree-sha1 = "d61f08c7bd15c5ab215fd7a2eb61c1ae15d8ff5e"
uuid = "ced4e74d-a319-5a8a-b0ac-84af2272839c"
version = "0.6.53"

    [deps.DistributionsAD.extensions]
    DistributionsADForwardDiffExt = "ForwardDiff"
    DistributionsADLazyArraysExt = "LazyArrays"
    DistributionsADReverseDiffExt = "ReverseDiff"
    DistributionsADTrackerExt = "Tracker"

    [deps.DistributionsAD.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.DynamicPPL]]
deps = ["AbstractMCMC", "AbstractPPL", "BangBang", "Bijectors", "ChainRulesCore", "Compat", "ConstructionBase", "Distributions", "DocStringExtensions", "LinearAlgebra", "LogDensityProblems", "MacroTools", "OrderedCollections", "Random", "Requires", "Setfield", "Test", "ZygoteRules"]
git-tree-sha1 = "50a718301941d4ec4f391aa845ee434fce2dbe2e"
uuid = "366bfd00-2699-11ea-058f-f148b4cae6d8"
version = "0.23.21"
weakdeps = ["MCMCChains"]

    [deps.DynamicPPL.extensions]
    DynamicPPLMCMCChainsExt = ["MCMCChains"]

[[deps.EllipticalSliceSampling]]
deps = ["AbstractMCMC", "ArrayInterface", "Distributions", "Random", "Statistics"]
git-tree-sha1 = "973b4927d112559dc737f55d6bf06503a5b3fc14"
uuid = "cad2338a-1db2-11e9-3401-43bc07c9ede2"
version = "1.1.0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "e90caa41f5a86296e014e148ee061bd6c3edec96"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "ec22cbbcd01cba8f41eecd7d44aac1f23ee985e3"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.7.2"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "25a10f2b86118664293062705fd9c7e2eda881a2"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.9.2"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "c6e4a1fbe73b31a3dea94b1da449503b8830c306"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.21.1"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9a68d75d466ccc1218d0552a8e1631151c569545"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.4.5"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "2d6ca471a6c7b536127afccfa7564b5b39227fe0"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.5"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "27442171f28c952804dede8ff72828a96f2bfc1f"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.10"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "025d171a2847f616becc0f84c8dc62fe18f0f6dd"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.10+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "e94c92c7bf4819685eb80186d51c43e71d4afa17"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.76.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "abbbb9ec3afd783a7cbd82ef01dcd088ea051398"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.1"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InplaceOps]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "50b41d59e7164ab6fda65e71049fee9d890731ff"
uuid = "505f98c9-085e-5b2c-8e89-488be7bf1f34"
version = "0.3.0"

[[deps.IntegerMathUtils]]
git-tree-sha1 = "b8ffb903da9f7b8cf695a8bead8e01814aa24b30"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.2"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "31d6adb719886d4e32e38197aae466e98881320b"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.0.0+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
deps = ["Dates", "Random"]
git-tree-sha1 = "3d8866c029dd6b16e69e0d4a939c4dfcb98fac47"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.8"
weakdeps = ["Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsStatisticsExt = "Statistics"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "68772f49f54b479fa88ace904f6127f0a3bb2e46"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.12"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "4ced6667f9974fc5c5943fa5e2ef1ca43ea9e450"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.8.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "a53ebe394b71470c7f97c2e7e170d51df21b17af"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.7"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60b1194df0a3298f460063de985eae7b01bc011a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.1+0"

[[deps.KernelAbstractions]]
deps = ["Adapt", "Atomix", "InteractiveUtils", "LinearAlgebra", "MacroTools", "PrecompileTools", "Requires", "SparseArrays", "StaticArrays", "UUIDs", "UnsafeAtomics", "UnsafeAtomicsLLVM"]
git-tree-sha1 = "81de11f7b02465435aab0ed7e935965bfcb3072b"
uuid = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
version = "0.9.14"

    [deps.KernelAbstractions.extensions]
    EnzymeExt = "EnzymeCore"

    [deps.KernelAbstractions.weakdeps]
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "90442c50e202a5cdf21a7899c66b240fdef14035"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.7"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Requires", "Unicode"]
git-tree-sha1 = "0678579657515e88b6632a3a482d39adcbb80445"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "6.4.1"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "98eaee04d96d973e79c25d49167668c5c8fb50e2"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.27+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f689897ccbe049adb19a065c495e75f372ecd42b"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.4+0"

[[deps.LRUCache]]
git-tree-sha1 = "5930ef949f30a9a947c69ef6b069c0b1aa27619d"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "f428ae552340899a935973270b8d98e5a31c49fe"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.1"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LatticeRules]]
deps = ["Random"]
git-tree-sha1 = "7f5b02258a3ca0221a6a9710b0a0a2e8fb4957fe"
uuid = "73f95e8e-ec14-4e6a-8b18-0d2e271c4e55"
version = "0.0.1"

[[deps.Lazy]]
deps = ["MacroTools"]
git-tree-sha1 = "1370f8202dac30758f3c345f9909b97f53d87d3f"
uuid = "50d2b5c4-7a5e-59d5-8109-a42b560f39c0"
version = "0.15.1"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "fb6803dafae4a5d62ea5cab204b1e657d9737e7f"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.2.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtask]]
deps = ["FunctionWrappers", "LRUCache", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "345a40c746404dd9cb1bbc368715856838ab96f2"
uuid = "6f1fad26-d15e-5dc8-ae53-837a1d7b8c9f"
version = "0.8.6"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "7bbea35cec17305fc70a0e5b4641477dc0789d9d"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.2.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogDensityProblems]]
deps = ["ArgCheck", "DocStringExtensions", "Random"]
git-tree-sha1 = "f9a11237204bc137617194d79d813069838fcf61"
uuid = "6fdf6af0-433a-55f7-b3ed-c6c6e0b8df7c"
version = "2.1.1"

[[deps.LogDensityProblemsAD]]
deps = ["DocStringExtensions", "LogDensityProblems", "Requires", "SimpleUnPack"]
git-tree-sha1 = "9c50732cd0f188766b6217ed6a2ebbdaf9890029"
uuid = "996a588d-648d-4e1f-a8f0-a84b347e47b1"
version = "1.7.0"

    [deps.LogDensityProblemsAD.extensions]
    LogDensityProblemsADADTypesExt = "ADTypes"
    LogDensityProblemsADEnzymeExt = "Enzyme"
    LogDensityProblemsADFiniteDifferencesExt = "FiniteDifferences"
    LogDensityProblemsADForwardDiffBenchmarkToolsExt = ["BenchmarkTools", "ForwardDiff"]
    LogDensityProblemsADForwardDiffExt = "ForwardDiff"
    LogDensityProblemsADReverseDiffExt = "ReverseDiff"
    LogDensityProblemsADTrackerExt = "Tracker"
    LogDensityProblemsADZygoteExt = "Zygote"

    [deps.LogDensityProblemsAD.weakdeps]
    ADTypes = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
    BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"
weakdeps = ["ChainRulesCore", "ChangesOfVariables", "InverseFunctions"]

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.MCMCChains]]
deps = ["AbstractMCMC", "AxisArrays", "Dates", "Distributions", "Formatting", "IteratorInterfaceExtensions", "KernelDensity", "LinearAlgebra", "MCMCDiagnosticTools", "MLJModelInterface", "NaturalSort", "OrderedCollections", "PrettyTables", "Random", "RecipesBase", "Statistics", "StatsBase", "StatsFuns", "TableTraits", "Tables"]
git-tree-sha1 = "3b1ae6bcb0a94ed7760e72cd3524794f613658d2"
uuid = "c7f686f2-ff18-58e9-bc7b-31028e88f75d"
version = "6.0.4"

[[deps.MCMCDiagnosticTools]]
deps = ["AbstractFFTs", "DataAPI", "DataStructures", "Distributions", "LinearAlgebra", "MLJModelInterface", "Random", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "6ea46c36b86320593d2017da3c28c79165167ef4"
uuid = "be115224-59cd-429b-ad48-344e309966f0"
version = "0.3.8"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "72dc3cf284559eb8f53aa593fe62cb33f83ed0c0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.0.0+0"

[[deps.MLJModelInterface]]
deps = ["Random", "ScientificTypesBase", "StatisticalTraits"]
git-tree-sha1 = "381d99f0af76d98f50bd5512dcf96a99c13f8223"
uuid = "e80e1ace-859a-464e-9ed9-23947d8ae3ea"
version = "1.9.3"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "9ee1618cbf5240e6d4e0371d6f24065083f60c48"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.11"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.MicroCollections]]
deps = ["BangBang", "InitialValues", "Setfield"]
git-tree-sha1 = "629afd7d10dbc6935ec59b32daeb33bc4460a42e"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.1.4"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "68bf5103e002c44adfd71fea6bd770b3f0586843"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.10.2"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NNlib]]
deps = ["Adapt", "Atomix", "ChainRulesCore", "GPUArraysCore", "KernelAbstractions", "LinearAlgebra", "Pkg", "Random", "Requires", "Statistics"]
git-tree-sha1 = "ac86d2944bf7a670ac8bf0f7ec099b5898abcc09"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.9.8"

    [deps.NNlib.extensions]
    NNlibAMDGPUExt = "AMDGPU"
    NNlibCUDACUDNNExt = ["CUDA", "cuDNN"]
    NNlibCUDAExt = "CUDA"
    NNlibEnzymeCoreExt = "EnzymeCore"

    [deps.NNlib.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    cuDNN = "02a925ec-e4fe-4b08-9a7e-0d78e3d38ccd"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "6d42eca6c3a27dc79172d6d947ead136d88751bb"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.10.0"

[[deps.NaturalSort]]
git-tree-sha1 = "eda490d06b9f7c00752ee81cfa451efe55521e21"
uuid = "c020b1a1-e9b0-503a-9c33-f039bfc54a85"
version = "1.0.0"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "3ef8ff4f011295fd938a521cb605099cecf084ca"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.15"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "2ac17d29c523ce1cd38e27785a7d23024853a4bb"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.10"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+2"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc6e1927ac521b659af340e0ca45828a3ffc748f"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.12+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "01f85d9269b13fedc61e63cc72ee2213565f7a72"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.7.8"

[[deps.Optimisers]]
deps = ["ChainRulesCore", "Functors", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "34205b1204cc83c43cd9cfe53ffbd3b310f6e8c5"
uuid = "3bd65402-5787-11e9-1adc-39752487f4e2"
version = "0.3.1"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "a935806434c9d4c506ba941871b327b96d41f2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.0"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "f92e1315dadf8c46561fb9396e525f7200cdc227"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.5"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "ccee59c6e48e6f2edf8a5b64dc817b6729f99eb5"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.39.0"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "88b895d13d53b5577fd53379d913b9ab9ac82660"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.3.1"

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "1d05623b5952aed1307bf8b43bec8b8d1ef94b6e"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.5"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "00099623ffee15972c16111bcf84c58a0051257c"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.9.0"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "37b7bb7aabf9a085e0044307e1717436117f2b3b"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.5.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9ebcd48c498668c7fa0e97a9cae873fbee7bfee1"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.1"

[[deps.QuasiMonteCarlo]]
deps = ["Accessors", "ConcreteStructs", "LatticeRules", "LinearAlgebra", "Primes", "Random", "Requires", "Sobol", "StatsBase"]
git-tree-sha1 = "cc086f8485bce77b6187141e1413c3b55f9a4341"
uuid = "8a4e6c94-4038-4cdc-81c3-7e6ffdb2a71b"
version = "0.3.3"
weakdeps = ["Distributions"]

    [deps.QuasiMonteCarlo.extensions]
    QuasiMonteCarloDistributionsExt = "Distributions"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "552f30e847641591ba3f39fd1bed559b9deb0ef3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.6.1"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "Requires", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "d7087c013e8a496ff396bae843b1e16d9a30ede8"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.38.10"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.Roots]]
deps = ["ChainRulesCore", "CommonSolve", "Printf", "Setfield"]
git-tree-sha1 = "0f1d92463a020321983d04c110f476c274bafe2e"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "2.0.22"

    [deps.Roots.extensions]
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"
    RootsSymPyExt = "SymPy"
    RootsSymPyPythonCallExt = "SymPyPythonCall"

    [deps.Roots.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"
    SymPyPythonCall = "bc8888f7-b21e-4b7c-a06a-5d9c9496438c"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "6aacc5eefe8415f47b3e34214c1d79d2674a0ba2"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.12"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SciMLBase]]
deps = ["ADTypes", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FillArrays", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "PrecompileTools", "Preferences", "Printf", "QuasiMonteCarlo", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables", "TruncatedStacktraces"]
git-tree-sha1 = "d432b4c4cc922fb7b21b555c138aa87f9fb7beb8"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.9.1"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["ArrayInterface", "DocStringExtensions", "Lazy", "LinearAlgebra", "Setfield", "SparseArrays", "StaticArraysCore", "Tricks"]
git-tree-sha1 = "51ae235ff058a64815e0a2c34b1db7578a06813d"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.7"

[[deps.ScientificTypesBase]]
git-tree-sha1 = "a8e18eb383b5ecf1b5e6fc237eb39255044fd92b"
uuid = "30f210dd-8aff-4c5f-94ba-8e64358c1161"
version = "3.0.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "0e7508ff27ba32f26cd459474ca2ede1bc10991f"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleUnPack]]
git-tree-sha1 = "58e6353e72cde29b90a69527e56df1b5c3d8c437"
uuid = "ce78b400-467f-4804-87d8-8f486da07d0a"
version = "1.1.0"

[[deps.Sobol]]
deps = ["DelimitedFiles", "Random"]
git-tree-sha1 = "5a74ac22a9daef23705f010f72c81d6925b19df8"
uuid = "ed01d8cd-4d21-5b2a-85b4-cc3bdc58bad4"
version = "1.5.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "5165dfb9fd131cf0c6957a3a7605dede376e7b63"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SparseInverseSubset]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "91402087fd5d13b2d97e3ef29bbdf9d7859e678a"
uuid = "dc90abb0-5640-4711-901d-7e5b23a2fada"
version = "0.1.1"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "e08a62abc517eb79667d0a29dc08a3b589516bb5"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.15"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "5ef59aea6f18c25168842bded46b16662141ab87"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.7.0"
weakdeps = ["Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.StatisticalTraits]]
deps = ["ScientificTypesBase"]
git-tree-sha1 = "30b9236691858e13f167ce829490a68e1a597782"
uuid = "64bff920-2084-43da-a3e6-9bb72801c0c9"
version = "3.2.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "1d77abd07f617c4868c33d4f5b9e1dbb2643c9cf"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.2"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f625d686d5a88bcd2b15cd81f18f98186fdc0c9a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.0"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "NaNMath", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "9115a29e6c2cf66cf213ccc17ffd61e27e743b24"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.15.6"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.StructArrays]]
deps = ["Adapt", "ConstructionBase", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "0a3db38e4cce3c54fe7a71f831cd7b6194a54213"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.16"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.SymbolicIndexingInterface]]
deps = ["DocStringExtensions"]
git-tree-sha1 = "f8ab052bfcbdb9b48fad2c80c873aa0d0344dfe5"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.2.2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.TerminalLoggers]]
deps = ["LeftChildRightSiblingTrees", "Logging", "Markdown", "Printf", "ProgressLogging", "UUIDs"]
git-tree-sha1 = "f133fab380933d042f6796eda4e130272ba520ca"
uuid = "5d786b92-1e48-4d6f-9151-6b4477ca9bed"
version = "0.1.7"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tracker]]
deps = ["Adapt", "DiffRules", "ForwardDiff", "Functors", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NNlib", "NaNMath", "Optimisers", "Printf", "Random", "Requires", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "bc54b1c65e87edfccf3f59d9ae7abb79f60d86f3"
uuid = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
version = "0.2.30"
weakdeps = ["PDMats"]

    [deps.Tracker.extensions]
    TrackerPDMatsExt = "PDMats"

[[deps.TranscodingStreams]]
git-tree-sha1 = "1fbeaaca45801b4ba17c251dd8603ef24801dd84"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.2"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Transducers]]
deps = ["Adapt", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "ConstructionBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "Setfield", "SplittablesBase", "Tables"]
git-tree-sha1 = "e579d3c991938fecbb225699e8f611fa3fbf2141"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.79"

    [deps.Transducers.extensions]
    TransducersBlockArraysExt = "BlockArrays"
    TransducersDataFramesExt = "DataFrames"
    TransducersLazyArraysExt = "LazyArrays"
    TransducersOnlineStatsBaseExt = "OnlineStatsBase"
    TransducersReferenceablesExt = "Referenceables"

    [deps.Transducers.weakdeps]
    BlockArrays = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    LazyArrays = "5078a376-72f3-5289-bfd5-ec5146d43c02"
    OnlineStatsBase = "925886fa-5bf2-5e8e-b522-a9147a512338"
    Referenceables = "42d2dcc6-99eb-4e98-b66c-637b7d73030e"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.Turing]]
deps = ["AbstractMCMC", "AdvancedHMC", "AdvancedMH", "AdvancedPS", "AdvancedVI", "BangBang", "Bijectors", "DataStructures", "Distributions", "DistributionsAD", "DocStringExtensions", "DynamicPPL", "EllipticalSliceSampling", "ForwardDiff", "Libtask", "LinearAlgebra", "LogDensityProblems", "LogDensityProblemsAD", "MCMCChains", "NamedArrays", "Printf", "Random", "Reexport", "Requires", "SciMLBase", "Setfield", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7cf779c99fbf6b2adfd3b5650ffdac21c0165489"
uuid = "fce5fe82-541a-59a6-adf8-730c64b5f9a0"
version = "0.29.3"

    [deps.Turing.extensions]
    TuringDynamicHMCExt = "DynamicHMC"
    TuringOptimExt = "Optim"

    [deps.Turing.weakdeps]
    DynamicHMC = "bbc10e6e-7c05-544b-b16e-64fede858acb"
    Optim = "429524aa-4258-5aef-a3af-852621145aeb"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"
weakdeps = ["ConstructionBase", "InverseFunctions"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "e2d817cc500e960fdbafcf988ac8436ba3208bfd"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.3"

[[deps.UnsafeAtomics]]
git-tree-sha1 = "6331ac3440856ea1988316b46045303bef658278"
uuid = "013be700-e6cd-48c3-b4a1-df204f14c38f"
version = "0.2.1"

[[deps.UnsafeAtomicsLLVM]]
deps = ["LLVM", "UnsafeAtomics"]
git-tree-sha1 = "323e3d0acf5e78a56dfae7bd8928c989b4f3083e"
uuid = "d80eeb9a-aca5-4d75-85e5-170c8b632249"
version = "0.1.3"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "fcdae142c1cfc7d89de2d11e08721d0f2f86c98a"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.6"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "5f24e158cf4cee437052371455fe361f526da062"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.6"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "801cbe47eae69adc50f36c3caec4758d2650741b"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.2+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522b8414d40c4cbbab8dee346ac3a09f9768f25d"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.5+0"

[[deps.Xorg_libICE_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "e5becd4411063bdcac16be8b66fc2f9f6f1e8fe5"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.0.10+1"

[[deps.Xorg_libSM_jll]]
deps = ["Libdl", "Pkg", "Xorg_libICE_jll"]
git-tree-sha1 = "4a9d9e4c180e1e8119b5ffc224a7b59d3a7f7e18"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.ZygoteRules]]
deps = ["ChainRulesCore", "MacroTools"]
git-tree-sha1 = "9d749cd449fb448aeca4feee9a2f4186dbb5d184"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.4"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a68c9655fbe6dfcab3d972808f1aafec151ce3f8"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.43.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "93284c28274d9e75218a416c65ec49d0e0fcdf3d"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.40+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─636d3550-a31b-11ee-3294-4f03381bbe16
# ╠═ee68848a-fafb-45b0-a2a4-7ab41e65c6d7
# ╟─77f3e7bb-eee4-44be-a8d3-df7467b57ab8
# ╟─eb7e532c-ef0b-4b90-8329-5d97d0b54b27
# ╠═6d070d28-d200-40d8-96ad-552cfd495886
# ╟─a5411ef8-0bc3-4746-b6b9-22ed85c272a5
# ╠═df06018b-5ec7-4ce9-aa11-ded117c88db6
# ╠═4689a3b1-5847-4422-9155-90a9e1948315
# ╠═79f58e4f-81a7-436d-a161-007185cfbf24
# ╟─4224e0aa-1895-438e-9d4e-9ae7c32202f4
# ╠═8259f21a-f564-4aa9-8659-0433a18c98ef
# ╠═0181790c-acad-4249-acd5-fe461384d1a5
# ╠═4c3b4428-120b-46da-9304-5f6bfd6bb7dc
# ╟─3be1250c-104c-4b4c-b73e-30e2703e4d3b
# ╠═35696e84-5c80-43a2-bbda-2ef5ccaf182f
# ╠═f0c5e11c-53e5-4b64-8fd8-dd9f677923ee
# ╟─3a22d31a-3b8c-463f-81ca-28947032daa3
# ╟─6863825f-3612-4355-99c6-b35ca643eb0f
# ╠═7d8ccb65-61fd-45a7-a666-6653d183c3bf
# ╟─3f20b43c-ce24-416e-99cc-4269572c7b34
# ╠═2d5cd3db-8e6a-4871-8d9f-129d2860dba3
# ╟─49fd413c-0e95-4437-a207-4abdeab585c0
# ╠═234d9cb7-bffa-4300-8f7e-4418ff3a271d
# ╠═91b4672d-2562-4692-b86b-f517b6fd3bce
# ╟─715ff1a9-d837-469f-895c-72fecb1bea42
# ╠═5a542f6c-2c55-4cb5-8991-a2ad54da006a
# ╟─d8837442-d3a9-4c42-8aea-b6f41ed705ef
# ╟─97fb6210-9e84-4b05-9e64-760eba1f555b
# ╠═aef6bb12-070f-4dc4-be26-7eff68775653
# ╟─881527e6-09e1-4d39-96dc-1040eb39575f
# ╠═39ff93a4-03bb-45d6-af8e-f3e25795470f
# ╠═86a88ba2-ede6-49b9-be3f-2dce4c180fd5
# ╟─b270d43a-f8ae-48a4-aa6f-bb529249c927
# ╠═96768615-fc0d-47d2-8ca5-412e0ee1223b
# ╟─043d9abf-b949-450e-b74c-735836ef3c94
# ╟─68977f18-407c-4a08-b1cd-2327178c09fc
# ╠═2669fe6f-cf08-4b94-99ed-7f5f8da5cdc0
# ╟─1ff89e57-bb59-4cbe-8f85-3dd906646166
# ╠═956b6f85-fa96-40b3-9fb5-a03faa65e312
# ╠═e6d19c9f-ebab-4ea4-85a1-df70dc5fda97
# ╟─7eb630a5-a246-43fa-9a4d-71e88e15c515
# ╠═642d0e43-9ff0-406c-b3c1-f02e98dd8437
# ╟─d8bed0c2-2360-4b1d-b2b7-f17821722db8
# ╟─e3cc94ae-87d2-4a91-ae59-a69a2083d952
# ╠═df90d887-767c-410e-82c0-7f40d478cc7f
# ╟─e2ffc103-8e2d-45d3-bc15-59bd9428a78d
# ╠═eb266d43-0e31-45b8-acd0-fca6e1edfa40
# ╠═43c3436f-99eb-4390-8274-6899b7a6e878
# ╟─93c0648f-27e5-427a-a1a1-544f1a9fb8e4
# ╠═a8600de4-f34a-4212-9835-85140aef6164
# ╟─26470b9a-8aaf-45f5-8930-a68050db96f0
# ╟─2000134e-7c31-425d-8217-322ad4b93851
# ╟─2ceb153f-ec2a-4e75-b923-7c124e499090
# ╠═7ae488c9-eb4e-472b-b358-7ec3e83d17ff
# ╟─8c609fee-a898-42ba-b505-a482ceeae94e
# ╠═abb96931-03d7-4fa2-972b-ac28521b588b
# ╠═437291ee-e579-4952-96a6-b578b7b670dc
# ╟─930f51fd-608b-4c22-9dd3-0660e922cdaf
# ╠═a86a25ab-4df3-40e2-955b-872c74370eaa
# ╠═b737d211-d720-4d11-8b28-88b7f906de92
# ╟─1e0f8067-8093-4582-99e2-d0cc0cff34fd
# ╠═535916aa-551c-4b4f-97f2-385012b0c03f
# ╠═2392db23-324e-4cc3-8d3f-ff992da3adb8
# ╟─a1b6ae3e-ab1a-4554-8b4c-3781a084c42a
# ╠═345d09a1-25ef-469b-96cf-6c50a64eee94
# ╟─cd3a3c82-e97d-4847-95f1-7cb392b1bc49
# ╠═8653dc8b-e259-4344-abf8-643b9faacd48
# ╟─0017b798-9791-43fa-85f9-56051805e2f7
# ╠═dc5a2213-7c32-467b-8652-6fe3f709960e
# ╠═a3598196-407d-4576-9dab-165b7917c296
# ╟─bccefcd7-184e-463a-a2f9-2f130bef2bbc
# ╠═374ba091-ca36-4e09-b4f4-2f4e012ac6ec
# ╟─eb75ff26-ca86-4b68-b171-aaa7cafc4700
# ╟─cb937079-5ace-43e1-8bbe-d5937b5eab89
# ╠═a8faf6ce-10c5-41e8-a8ec-76a6179ef70d
# ╟─acdc1984-0c5c-4cdb-963c-66fec11126c7
# ╠═c9bb9d7d-4b2b-4fb9-8b67-68df8302a943
# ╠═d0baf1f4-5525-46de-8b25-53415abdba73
# ╠═8ae2b37e-fbe0-4600-ac27-84ab6d31ca12
# ╠═bc0fecca-58df-445f-849f-1b4d973be9c4
# ╟─885a8498-7ce6-4635-8950-61d0b257080b
# ╟─55f1ffaa-d734-4b3b-a93f-b9f98fceeb95
# ╟─85aa1de8-137f-49d3-ac44-b96294e8a7f1
# ╟─8695b6e8-cff6-4c96-b9cc-035ee4da6d83
# ╟─57d5c51d-00c5-4290-a04a-7aeb9ed76679
# ╠═24411b77-7bfb-4412-8e44-1aaa2edfbbac
# ╟─a62bafcd-d75b-4ef6-b1c3-146f4832da28
# ╠═67c33d41-3bf5-4ad5-8498-832182d38e35
# ╠═abb6df8e-8a36-4325-ad44-185d4620d866
# ╟─7a205344-a95b-45d9-ad48-145f9f8015aa
# ╠═01d1765a-146f-4573-9416-40a4337926fd
# ╠═02ee039c-58b9-46fd-8cb0-56b549bd4c0d
# ╠═9fbdae19-39aa-43c6-898e-47b31230ddc9
# ╠═b8845cfa-cb03-45f3-ad7a-aaaf6bbe4435
# ╟─f92a6832-d16b-4617-b048-896c99ebf732
# ╠═7f3d3928-9d51-48f0-a829-dd53bbe12105
# ╠═24f8ee20-f080-4138-859a-a4a0810ae51a
# ╟─746578be-d8c6-42b7-879b-d2e0761326b9
# ╟─b9a2947e-e0a3-4176-94f3-a38229e9c208
# ╠═2f6574e9-c7b0-4142-bccb-70dc97b9f93e
# ╟─1d3c754f-83ee-4e24-b3f0-1cbb74264f61
# ╠═9c5f2833-39d5-4d8e-97f2-96a514d9cd53
# ╠═8cfd8e19-3792-4a14-98ba-a8a5c0c15d8e
# ╠═acf76b7f-0ea5-4abb-9e46-5da914470ba7
# ╟─854682c4-d17d-4629-bdba-476957d2d377
# ╠═a4884c1f-db4a-4439-a958-dc01e76c6c4d
# ╠═8c78f211-a32f-4304-860a-68a1ee34ad2a
# ╠═3b879379-3a93-4697-a6e5-551e4ef18e0c
# ╟─ecd5963a-c919-48de-b25b-21ccca123418
# ╟─cca0e064-6013-4229-8f93-159bcc264682
# ╟─6970b91d-530e-44a4-b6da-9982f5100ae0
# ╟─60e66b48-57ae-4df8-a066-f64f7930b1f8
# ╠═442ae531-96a1-42a7-a02a-fa949986bcd1
# ╟─907df583-2f40-40cb-bf73-06f8f98a17a2
# ╠═7cccd9ac-0011-4614-9712-ba1fbd12f136
# ╠═d1853cca-7276-42ed-9a06-c9c46d059881
# ╠═825f717a-c110-4b22-aa7e-342ee8479113
# ╠═3fc5d9c0-6d96-4f49-8302-2ca574bf9699
# ╟─8702025d-00ba-4d10-83a3-47c44f0a272f
# ╠═4ea11602-83c4-4bdd-9525-9a6698183397
# ╟─32e0a393-bd3e-40f0-9244-d85cfef14560
# ╟─06db4af2-7aa0-4f44-bfe1-cab4d11c7f45
# ╠═24387f02-4b28-4cc0-9213-a501437bd7ee
# ╟─1c1ed766-c9ad-433b-8edc-d2759c9384e7
# ╠═cc96c101-aa78-4b24-84e5-3f4917a89131
# ╟─119efa48-fd32-4420-b57a-df822abc5ea0
# ╠═83f043f6-bb14-415c-9a0f-38ba2ff7a423
# ╠═8a6d5609-a51c-4d0a-83ac-5a33b41ca66a
# ╟─37839eb8-c914-4314-a11b-1eb65e41ab06
# ╠═d3c5d38b-88af-4edd-b7b2-bc197dfcf005
# ╟─cebbfd86-428e-4ca2-ac2a-08615a28527d
# ╟─4e976941-48c4-478b-8d5a-b3cd468b6076
# ╟─3e910200-0ec6-4455-8095-ac5d0d642ed5
# ╠═9ddc224e-496b-4205-97df-07377bcc146f
# ╟─8f78ebf4-ed0d-4607-b63f-27d10c11d99a
# ╠═ef2927b1-7ff5-44ac-8381-ec784896bb61
# ╠═6936ff5e-a0b9-47fa-bbdc-c6aa8a84fdde
# ╠═007f26ae-0fd9-464f-a2ae-274480258dfa
# ╠═752324ab-8acd-4645-883b-34baf4060dd6
# ╟─fc79cd60-3c60-4186-9758-eeb56e95ea9a
# ╠═38b47426-1020-48d5-91db-ce57c456bd5c
# ╟─aa409459-3526-4849-82ba-02293118953a
# ╠═bfb3fba9-2617-4615-a4d0-39c117a75c96
# ╠═8815a023-aa00-421c-bb6b-724df77aed4a
# ╠═a121488d-d71d-4907-b9d3-7f49eabe2840
# ╟─180c8256-1f89-422b-9391-b7d6d1bf981f
# ╟─daf5c968-796e-4079-8713-88dfc93fd00b
# ╟─1767adc8-5496-4e18-8be2-ec0342f9c4da
# ╟─171970d1-2c37-46de-8771-77f32d3a7308
# ╠═63941183-4d6c-42d5-a334-7e6bdd7e036a
# ╠═093718f0-2299-4c2c-b5ef-8b1c06d0d09b
# ╠═b2beba89-e464-48f5-93f7-e1432f1e7f54
# ╠═ed3328b6-f0cb-440c-a116-68dcb754930b
# ╠═565448e8-6d48-4946-b65d-be6a9b8247b0
# ╟─ccb1f9a0-09de-4697-93b0-943e7fd6cdcf
# ╟─39b0166b-6568-4482-8f2e-c44082c2284c
# ╠═2a206181-cbcd-4a76-8d10-c151a911ddb8
# ╟─a8039911-1ee5-40ff-ad2d-e38e3c8b5c39
# ╠═e71c5a7b-e724-46e2-bb62-11bfa33b6e93
# ╠═53283fe4-d7d5-4d04-8d12-df9ae05ae326
# ╟─c0406b45-2fe2-47ee-9fb1-fe6d8b4036a5
# ╠═734c94e9-95e5-4240-bb3a-b9af1826e51d
# ╠═cb93d964-7fa9-4520-b7a1-3772c5872447
# ╟─8ac85301-6bb5-4d06-aff0-1eedc5353d6d
# ╟─d56230ef-54e5-4867-b5a2-663cc5e384fd
# ╟─1afaa80d-0f11-476f-8f1c-799c36268c59
# ╠═4cb28df6-0945-446e-a042-5391b958e426
# ╠═af0d0a5e-64cd-4f58-b2ba-ccbd45642d99
# ╠═44925d7b-667b-4fc1-b942-d30005503e85
# ╠═cc990d60-05c6-4033-aaf6-15993966040b
# ╠═4f5ee761-f254-4a15-85a7-8a085bb0f26a
# ╠═7221a4f4-2127-4b6e-89bb-531d44ce3af8
# ╠═28bfbb06-8834-4b31-a26c-34bed249708b
# ╠═747d8f68-6560-4d9c-8ee5-0f0143567773
# ╠═4b0921c9-b549-4edc-8486-992df4f2baa2
# ╟─d5d5e777-523f-4802-9428-7bcb97eef394
# ╟─07bff31d-da31-49f3-8439-fd99effa00f6
# ╟─83513428-dbd3-44d5-a4d6-cc722d0513fa
# ╟─4a1847fc-b9d0-431d-90de-d53cda117754
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
