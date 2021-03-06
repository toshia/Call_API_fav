# -*- coding:utf-8 -*-

def xorshift128_sleep(stime)
  x = 123456789; y = 362436069; z = 521288629; w = 88675123
  t = 0
  x = Time.now.to_i
  t = x ^ (x << 11)
  x = y; y = z; z = w
  w = (w ^ (w >> 19)) ^ (t ^ (t >> 8))
  sleep(rand(stime.to_i)+ (w%10).to_i)
end

Plugin.create(:call_api_fav) do

  querybox = Gtk::Entry.new()
  searchbtn = Gtk::Button.new('ふぁぼ候補')

  tab(:call_api_fav, 'Call_Api_ToFav') do
    set_icon File.expand_path(File.join(File.dirname(__FILE__), 'target.png'))
    shrink
    nativewidget Gtk::HBox.new(false, 0).pack_start(querybox).closeup(searchbtn)
    expand
    timeline :call_api_fav
  end

  searchbtn.signal_connect('clicked'){ |elm|
    favnum = (UserConfig[:retrive_fav_give]||10).to_i
    stime = (UserConfig[:retrive_fav_delay]||1).to_i
    
	#遅延ふぁぼを有効(true)|無効(false)にします
    #有効にするとmikutterが重くなる可能性があります
	is_sleep = (UserConfig[:retrive_fav_isdelay]|| false)

    timeline(:call_api_fav).clear
    #テキストボックスが空なら何もしないよ
    if querybox.text.size > 0 then
      screen_name = querybox.text
      Thread.new {
        user = User.findbyidname("#{screen_name}", true)
        Deferred.fail "user @#{screen_name} not found." if not user
        user
      }.next { |user|
        Service.primary.user_timeline(:user_id => user[:id],
                                      :no_auto_since_id => true,
                                      :count => favnum.to_i)
      }.next { |res|
        timeline(:call_api_fav) << res
        res.each do |mes|
          unless mes.favorite? || mes.retweet?
            if is_sleep == true then
              Reserver.new(xorshift128_sleep(stime)){
                #ふぁぼふぁぼするよ
                mes.favorite(true)
              }
            else
              #ふぁぼふぁぼするよ
              mes.favorite(true)
            end
          end
        end
      }.terminate("@#{screen_name} をふぁぼれませんでした")
    end
  }

  #設定から与えるふぁぼ数を設定するよ
  settings "call_api_fav" do
    settings "何ふぁぼ与えるかを選択してください" do
      adjustment('ふぁぼる回数', :retrive_fav_give, 1, 127)
      boolean('遅延ふぁぼを行う', :retrive_fav_isdelay);
      adjustment('遅延時間', :retrive_fav_delay, 1, 60)
    end
  end
end
