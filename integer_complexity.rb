class String
	def is_valid_number?(min)
		begin
			if Integer(self)
			end
			self.to_i >= min
		rescue
			false
		end
	end
end

class FactorsProduct
	attr_accessor(:result)
	attr_accessor(:factors)

	def initialize
		@result = 1
		@factors = Array.new
	end

	def push(factor)
		@result *= factor
		@factors.push(factor)
	end

	def pop
		@result /= @factors.pop
	end

	def clone
		product = FactorsProduct.new
		product.result = @result
		@factors.each do |factor|
			product.factors.push(factor)
		end
		product
	end
end

class ComplexitySum
	attr_accessor(:result)
	attr_accessor(:products)

	def push_to_product(product_idx, factor, cache)
		@result -= cache[@products[product_idx].result-1]
		@products[product_idx].push(factor)
		@result += cache[@products[product_idx].result-1]
	end

	def pop_from_product(product_idx, cache)
		@result -= cache[@products[product_idx].result-1]
		@products[product_idx].pop
		@result += cache[@products[product_idx].result-1]
	end

	def push(factor, cache)
		product = FactorsProduct.new
		product.push(factor)
		@result += cache[product.result-1]
		@products.push(product)
	end

	def pop(cache)
		product = @products.pop
		@result -= cache[product.result-1]
	end

	def initialize(factors, cache_max, cache)
		@result = 0
		@products = Array.new
		product = cache_max
		product_idx = -1
		factors.each do |factor|
			if product*factor <= cache_max
				push_to_product(product_idx, factor, cache)
				product *= factor
			else
				push(factor, cache)
				product = factor
				product_idx += 1
			end
		end
	end

	def clone
		complexity_sum = ComplexitySum.new(Array.new, 1, Array.new)
		complexity_sum.result = @result
		@products.each do |product|
			complexity_sum.products.push(product.clone)
		end
		complexity_sum
	end
end

class Operation
	attr_accessor(:operator)
	attr_accessor(:operand)

	def initialize(operator, operand)
		@operator = operator
		@operand = operand
	end
end

class IntegerComplexity
	def push_factor(factors, factor_idx, factors_n, complexity_sum, product_idx, products_n)
		if complexity_sum.result >= @complexity_sum_min.result
			return
		end
		if factor_idx == factors_n
			@complexity_sum_min = complexity_sum.clone
			return
		end
		if factors[factor_idx] < factors[factor_idx-1]
			product_idx = 0
		end
		while product_idx < products_n
			if complexity_sum.products[product_idx].result*factors[factor_idx] <= @cache_max
				complexity_sum.push_to_product(product_idx, factors[factor_idx], @cache)
				push_factor(factors, factor_idx+1, factors_n, complexity_sum, product_idx, products_n)
				complexity_sum.pop_from_product(product_idx, @cache)
			end
			product_idx += 1
		end
		if products_n < @products_max
			complexity_sum.push(factors[factor_idx], @cache)
			push_factor(factors, factor_idx+1, factors_n, complexity_sum, products_n, products_n+1)
			complexity_sum.pop(@cache)
		end
	end

	def set_complexity_sum_min(factors)
		@complexity_sum_min = ComplexitySum.new(factors, @cache_max, @cache)
		@products_max = @complexity_sum_min.products.size
		complexity_sum = ComplexitySum.new(factors[0..0], @cache_max, @cache)
		push_factor(factors, 1, factors.size, complexity_sum, 0, 1)
	end

	def set_operation(depth, operator, operand)
		if depth == @depth_max
			@operations.push(Operation.new(operator, operand))
			@depth_max += 1
			puts "depth_max #{@depth_max}"
		else
			@operations[depth].operator = operator
			@operations[depth].operand = operand
		end
	end

	def set_operations(base_depth, complexity_sum)
		complexity_sum.products.each_with_index do |product, product_idx|
			set_operation(base_depth+product_idx, "*", product.result)
		end
	end

	def print_operation(show_complexity, depth)
		if @operations[depth].operator.eql? "+"
			print "("
		end
		if show_complexity == 1
			print "#{@cache[@operations[depth].operand-1]}"
		else
			print "#{@operations[depth].operand}"
		end
		if !@operations[depth].operator.eql? " "
			if show_complexity == 1
				print "+"
			else
				print "#{@operations[depth].operator}"
			end
			print_operation(show_complexity, depth+1)
		end
		if @operations[depth].operator.eql? "+"
			print ")"
		end
	end

	def print_expression(title, show_complexity)
		print "#{title} = "
		print_operation(show_complexity, 0)
		puts ""
	end

	def set_complexity_min(base_depth, full_depth, base_complexity, full_complexity, rem, prime_idx, factors, complexity_sum)
		if rem <= @cache_max
			if full_complexity+@cache[rem-1] < @complexity_min
				set_operation(full_depth, " ", rem)
				@complexity_min = full_complexity+@cache[rem-1]
				print_expression("expression", 0)
				print_expression("complexity", 1)
				puts "complexity_min = #{@complexity_min}"
				STDOUT.flush
			end
			return
		end
		if rem < 6
			lower = rem
		else
			pow3 = 9
			lower = 3
			while pow3 <= rem && full_complexity+lower < @complexity_min
				pow3 *= 3
				lower += 3
			end
			if full_complexity+lower < @complexity_min
				pow3 /= 3
				if pow3*2 <= rem
					lower += 2
				else
					pow3 /= 3
					if pow3*4 <= rem
						lower += 1
					end
				end
			end
		end
		if full_complexity+lower >= @complexity_min
			return
		end
		while prime_idx < @primes_n && (@primes[prime_idx]*@primes[prime_idx] > rem || rem%@primes[prime_idx] > 0)
			prime_idx += 1
		end
		if prime_idx < @primes_n
			factors.push(@primes[prime_idx])
			set_complexity_sum_min(factors)
			set_operations(base_depth, @complexity_sum_min)
			set_complexity_min(base_depth, base_depth+@complexity_sum_min.products.size, base_complexity, base_complexity+@complexity_sum_min.result, rem/@primes[prime_idx], prime_idx, factors, @complexity_sum_min)
			factors.pop
			set_operations(base_depth, complexity_sum)
			set_complexity_min(base_depth, full_depth, base_complexity, full_complexity, rem, prime_idx+1, factors, complexity_sum)
		else
			set_operation(full_depth, "+", 1)
			set_complexity_min(full_depth+1, full_depth+1, full_complexity+@cache[0], full_complexity+@cache[0], rem-@cache[0], 0, Array.new, ComplexitySum.new(Array.new, 1, Array.new))
		end
	end

	def initialize(n, cache_max)
		@cache_max = cache_max
		@cache = Array.new
		for i in 1..@cache_max
			@cache.push(i)
		end
		for i in 2..@cache_max
			if @cache[0]+@cache[i-2] < @cache[i-1]
				@cache[i-1] = @cache[0]+@cache[i-2]
			end
			j = 2
			while j <= i && i*j <= @cache_max
				if @cache[i-1]+@cache[j-1] < @cache[i*j-1]
					@cache[i*j-1] = @cache[i-1]+@cache[j-1]
				end
				j += 1
			end
		end
		factors = Array.new
		for i in 2..@cache_max
			factors.push(0)
		end
		@primes = Array.new
		for i in 2..@cache_max
			if factors[i-2] == 0
				@primes.push(i)
				for j in (i*2..@cache_max).step(i)
					factors[j-2] = 1
				end
			end
		end
		@primes.reverse!
		@primes_n = @primes.size
		@depth_max = 0
		@operations = Array.new
		@complexity_min = n
		set_complexity_min(0, 0, 0, 0, n, 0, Array.new, ComplexitySum.new(Array.new, 1, Array.new))
	end
end

if ARGV.size == 2 && ARGV[0].is_valid_number?(1) && ARGV[1].is_valid_number?(2)
	IntegerComplexity.new(ARGV[0].to_i, ARGV[1].to_i)
end
