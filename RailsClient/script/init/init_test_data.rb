l1 = Location.create(id:'L001',name:'Outter Warehouse',address:'Shanghai',tel:'2913123')
l2 = Location.create(id:'L002',name:'Factory',address:'Suzhou',tel:'2123913123')
u = User.create(id:'user001',password:'1111',password_confirmation:'1111')
u.location = l1
u.role_id = 300
u.save
Whouse.create(id:'WH001',name:'3MB',location_id:'L002')
Position.create(id:'PS001',whouse_id:'WH001',detail:'01 01 04')
Part.create(id:'PT001',user_id:'user001')
Part.create(id:'PT002',user_id:'user001')