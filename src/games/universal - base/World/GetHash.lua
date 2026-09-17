local GetHash

GetHash = vape.Categories.World:CreateModule({
	Name = 'GetHash',
	Function = function(callback)
		if callback then
            local data = lplr.Name..lplr.UserId
			setclipboard(hash and hash.sha512(data..'SelfReport') or '')
		end
	end
})