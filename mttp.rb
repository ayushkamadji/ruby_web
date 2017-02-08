class MHTTPMessage
  attr_reader :msg
  
  def initialize(message)
    @msg = {}
    hdrr = /(?<=\r\n)(^.+)(?=\r\n)/
    bdyr = /(?<=\r\n\r\n)(.*)/m
    
    @msg[:type], @msg[:startline] = get_sline_and_type(message)

    @msg[:headers] = message.scan(hdrr).flatten 
    @msg[:body] = message.scan(bdyr).flatten[0]
  end


  def get_sline_and_type(message)
    slnr = /\A.*(?=\r\n)/

    reqlmetr = /\A[\S&&[^\/]]*/
    reqltarr = /(?<=\s).+(?=\s)/
    reqlhvrr = /HTTP\/\d\.\d*/
    stalhvrr = /\AHTTP\/\d\.\d*/
    stalcodr = /\d\d\d/
    stalrphr = /(?<=\d\d\d\s)(.+)(?=$)/

    start_line = message.scan(slnr).flatten[0]

    sln_hsh = {}
    
    if !stalhvrr.match(start_line).nil?
      type = :response
      sln_hsh[:httpver] = start_line.scan(stalhvrr).flatten[0]
      sln_hsh[:code] = start_line.scan(stalcodr).flatten[0].to_i
      sln_hsh[:reason] = start_line.scan(stalrphr).flatten[0]
    else
      type = :request
      sln_hsh[:method] = start_line.scan(reqlmetr).flatten[0]
      sln_hsh[:target] = start_line.scan(reqltarr).flatten[0]
      sln_hsh[:httpver] = start_line.scan(reqlhvrr).flatten[0]
    end

    return [type, sln_hsh]
  end

end
