/* Local fixture: real Ext JS and Proxmox widgets, synthetic data, no remote API. */
Ext.onReady(function () {
    Ext.tip.QuickTipManager.init();
    Ext.Ajax.on('beforerequest', function () { return false; });
    const E = Ext.String.htmlEncode;
    const themeLink = document.getElementById('preview-theme');
    if (new URLSearchParams(location.search).get('theme') === 'stock') themeLink.disabled = true;
    const store = (fields, data) => Ext.create('Ext.data.Store', {fields, data});
    const status = value => '<span class="fa fa-circle ' + (value === 'Running' || value === 'Active' || value === 'OK' ? 'good' : value === 'Warning' ? 'warning' : '') + '" aria-hidden="true"></span> ' + E(value);
    const tag = value => '<span class="proxmox-tag" style="background:#dcebf4;color:#24516a;padding:2px 5px">' + E(value) + '</span>';
    const grid = (columns, data, extra = {}) => ({xtype:'grid', border:false, columnLines:false,
        store:store(columns.map(c=>c.dataIndex).filter(Boolean),data),columns,
        viewConfig:{stripeRows:true,emptyText:'No records to display.',deferEmptyText:false}, ...extra});
    const field = (name,value,extra={}) => ({xtype:'textfield',fieldLabel:name,value,anchor:'100%',labelWidth:130,...extra});
    const showLog = () => Ext.create('Ext.window.Window', {
        title:'Task viewer: Backup',width:820,height:500,modal:true,layout:'fit',maximizable:true,
        items:[{xtype:'tabpanel',items:[{title:'Output',xtype:'panel',scrollable:true,bodyPadding:16,
            html:'<pre style="font:12px/1.8 Consolas,monospace">'+Array.from({length:140},(_,i)=>E('INFO: '+String(i).padStart(3,'0')+'  '+(i===139?'TASK OK':'Backing up disk scsi0: '+Math.min(99,i)+'% complete'))).join('\n')+'</pre>'},
            {title:'Status',bodyPadding:20,html:'<p>Task status: <strong class="good">OK</strong></p><p>Duration: 00:02:41</p>'}]}],
        buttons:[{text:'Close',handler:b=>b.up('window').close()}]
    }).show();
    const showWizard = () => {
        const pages=[
            {title:'General',items:[field('Node','pve-edge-01',{xtype:'combo',store:['pve-edge-01','pve-edge-02'],editable:false}),field('VM ID',104,{xtype:'numberfield',minValue:100}),field('Name','',{allowBlank:false,emptyText:'Enter a virtual machine name'}),{xtype:'checkbox',boxLabel:'Start at boot',checked:true}]},
            {title:'OS',items:[field('Storage','local',{xtype:'combo',store:['local','fast-nvme'],editable:false}),field('ISO image','debian-12.9-amd64.iso',{xtype:'combo',store:['debian-12.9-amd64.iso','ubuntu-24.04.iso']}),field('Type','Linux',{xtype:'combo',store:['Linux','Microsoft Windows','Other']})]},
            {title:'System',items:[field('BIOS','OVMF (UEFI)',{xtype:'combo',store:['OVMF (UEFI)','SeaBIOS']}),field('Machine','q35'),{xtype:'checkbox',boxLabel:'Qemu Agent',checked:true}]},
            {title:'Disks',items:[field('Storage','fast-nvme',{xtype:'combo',store:['fast-nvme','local-lvm']}),field('Disk size (GiB)',64,{xtype:'numberfield',minValue:1}),{xtype:'checkbox',boxLabel:'Discard',checked:true}]},
            {title:'CPU',items:[field('Sockets',1,{xtype:'numberfield',minValue:1}),field('Cores',4,{xtype:'numberfield',minValue:1}),field('Type','host')]},
            {title:'Memory',items:[field('Memory (MiB)',8192,{xtype:'numberfield',minValue:512}),{xtype:'checkbox',boxLabel:'Ballooning Device',checked:true}]},
            {title:'Network',items:[field('Bridge','vmbr0',{xtype:'combo',store:['vmbr0','vmbr1']}),field('VLAN Tag','',{xtype:'numberfield',allowBlank:true}),{xtype:'checkbox',boxLabel:'Firewall',checked:true}]},
            {title:'Confirm',items:[{xtype:'displayfield',value:'Local preview only. No virtual machine will be created.'}]}
        ];
        const tabs=Ext.create('Ext.tab.Panel',{itemId:'wizard-tabs',activeTab:0,items:pages.map(p=>({xtype:'form',title:p.title,bodyPadding:24,defaults:{labelWidth:130,anchor:'100%'},items:p.items}))});
        Ext.create('Ext.window.Window',{title:'Create: Virtual Machine',width:760,height:450,modal:true,layout:'fit',items:[tabs],buttons:[
            {text:'Back',handler:()=>tabs.setActiveTab(Math.max(0,tabs.items.indexOf(tabs.getActiveTab())-1))},
            {text:'Next',handler:()=>{const active=tabs.getActiveTab();if(active.isValid()) tabs.setActiveTab(Math.min(7,tabs.items.indexOf(active)+1));}},
            {text:'Cancel',handler:b=>b.up('window').close()}]}).show();
    };
    const showSettings = () => Ext.create('Ext.window.Window',{
        title:'Edit: Network Device',width:580,height:380,modal:true,layout:'fit',items:[{xtype:'form',bodyPadding:24,defaults:{labelWidth:135,anchor:'100%'},items:[
            field('Bridge','vmbr0',{xtype:'combo',store:['vmbr0','vmbr1','vmbr2'],editable:false}),
            field('Model','VirtIO (paravirtualized)',{xtype:'combo',store:['VirtIO (paravirtualized)','Intel E1000']}),
            field('MAC address','BC:24:11:00:10:01',{readOnly:true}),field('VLAN Tag',20,{xtype:'numberfield',minValue:1,maxValue:4094}),
            {xtype:'checkbox',boxLabel:'Firewall',checked:true},{xtype:'checkbox',boxLabel:'Disconnect',disabled:true}
        ]}],buttons:[{text:'Cancel',handler:b=>b.up('window').close()},{text:'OK',handler:b=>b.up('window').close()}]
    }).show();
    const showLogin = () => Ext.create('Ext.window.Window',{
        title:'Proxmox VE Login',width:440,height:330,modal:true,layout:'fit',items:[{xtype:'form',bodyPadding:24,defaults:{anchor:'100%',labelWidth:105},items:[
            field('User name','',{allowBlank:false}),field('Password','',{inputType:'password',allowBlank:false}),
            field('Realm','Linux PAM standard authentication',{id:'pveloginrealm',xtype:'combo',store:['Linux PAM standard authentication','Proxmox VE authentication server'],editable:false}),
            field('Language','English',{xtype:'combo',store:['English','Deutsch']}),{xtype:'checkbox',boxLabel:'Save User name'}
        ]}],buttons:[{text:'Close preview',handler:b=>b.up('window').close()},{text:'Login',handler:b=>b.up('window').down('form').isValid()}]
    }).show();
    const times = Array.from({length:32},(_,i)=>({time:Date.UTC(2026,9,15,8,i*2),cpu:18+Math.sin(i*.7)*9+(i%9===0?13:0),io:3+Math.sin(i*.4)*2,mem:62+Math.sin(i*.3)*3,net:8+Math.sin(i*.6)*5,out:3+Math.sin(i*.4)*2}));
    const chart=(title,fields,fieldTitles,unit)=>({xtype:'proxmoxRRDChart',title,fields,fieldTitles,unit,
        store:store(['time','cpu','io','mem','net','out'],times),height:255,flex:1,margin:'0 0 12 0'});
    const summary={xtype:'panel',itemId:'summary',border:false,scrollable:true,bodyPadding:16,layout:{type:'vbox',align:'stretch'},items:[
        {xtype:'panel',title:'pve-edge-01',margin:'0 0 14 0',bodyPadding:'14 18',layout:{type:'hbox',align:'stretch'},items:[
            {xtype:'container',flex:1,defaults:{xtype:'displayfield',labelWidth:105},items:[{fieldLabel:'Status',value:status('Running')},{fieldLabel:'Uptime',value:'24 days, 18:42:06'},{fieldLabel:'CPU(s)',value:'24 × Intel Xeon E-2288G'},{fieldLabel:'Kernel',value:'Linux 6.8.12-17-pve'}]},
            {xtype:'container',flex:1,defaults:{xtype:'displayfield',labelWidth:110},items:[{fieldLabel:'CPU usage',value:'22.4% of 24 CPUs'},{xtype:'progressbar',value:.224,text:'22.4%',margin:'0 0 10 0'},{fieldLabel:'Memory usage',value:'62.8 GiB of 128 GiB'},{xtype:'progressbar',value:.49,text:'49.1%'}]},
            {xtype:'container',flex:1,padding:'0 0 0 24',defaults:{xtype:'displayfield',labelWidth:110},items:[{fieldLabel:'Storage usage',value:'1.42 TiB of 3.84 TiB'},{xtype:'progressbar',value:.37,text:'37.0%',margin:'0 0 10 0'},{fieldLabel:'IO delay',value:'0.12%'},{fieldLabel:'Repository',value:'<span class="good">Up to date</span>'}]}
        ]},
        {xtype:'container',layout:{type:'hbox',align:'stretch'},items:[{...chart('CPU usage',['cpu','io'],['CPU usage','IO delay'],'percent'),margin:'0 12 12 0'},chart('Memory usage',['mem'],['Memory'],'percent')]},
        {xtype:'container',layout:{type:'hbox',align:'stretch'},items:[{...chart('Network traffic',['net','out'],['Incoming','Outgoing'],'bytespersecond'),margin:'0 12 12 0'},chart('Server load',['cpu'],['Load average'],'')]}
    ]};
    const vmData=[
        {id:100,name:'gateway',state:'Running',node:'pve-edge-01',cpu:'1.2%',memory:'1.8 / 4 GiB',disk:'32 GiB',tag:'network'},
        {id:101,name:'app-server',state:'Running',node:'pve-edge-01',cpu:'8.4%',memory:'6.2 / 16 GiB',disk:'128 GiB',tag:'production'},
        {id:102,name:'database',state:'Running',node:'pve-edge-01',cpu:'12.8%',memory:'22.4 / 32 GiB',disk:'512 GiB',tag:'production'},
        {id:103,name:'build-runner',state:'Stopped',node:'pve-edge-02',cpu:'0.0%',memory:'0 / 8 GiB',disk:'64 GiB',tag:'development'},
        {id:104,name:'monitoring',state:'Running',node:'pve-edge-02',cpu:'2.6%',memory:'3.1 / 8 GiB',disk:'64 GiB',tag:'operations'},
        {id:105,name:'backup-proxy',state:'Running',node:'pve-edge-02',cpu:'0.9%',memory:'1.1 / 4 GiB',disk:'32 GiB',tag:'operations'}
    ];
    const vmColumns=[{text:'VM ID',dataIndex:'id',width:75},{text:'Name',dataIndex:'name',flex:1,minWidth:140},{text:'Status',dataIndex:'state',width:105,renderer:status},{text:'Node',dataIndex:'node',width:130},{text:'CPU',dataIndex:'cpu',width:75},{text:'Memory',dataIndex:'memory',width:135},{text:'Disk',dataIndex:'disk',width:85},{text:'Tags',dataIndex:'tag',width:115,renderer:tag}];
    const vms=grid(vmColumns,vmData,{itemId:'vms',tbar:[{text:'Create VM',iconCls:'fa fa-plus',handler:showWizard},'-',{text:'Start',iconCls:'fa fa-play',disabled:true},{text:'Shutdown',iconCls:'fa fa-power-off',disabled:true},{text:'More',menu:[{text:'Clone',disabled:true},{text:'Migrate',disabled:true}]},'->',{xtype:'textfield',emptyText:'Filter virtual machines…',width:210,listeners:{change:(f,v)=>f.up('grid').getStore().filterBy(r=>r.get('name').includes(v))}}],listeners:{itemdblclick:showSettings}});
    const storage=grid([{text:'Name',dataIndex:'name',flex:1},{text:'Type',dataIndex:'type',width:140},{text:'Status',dataIndex:'state',width:110,renderer:status},{text:'Total',dataIndex:'total',width:110},{text:'Used',dataIndex:'used',width:110},{text:'Content',dataIndex:'content',flex:1}],
        [{name:'local',type:'Directory',state:'Active',total:'96 GiB',used:'18.4 GiB',content:'ISO image, Container template'},{name:'fast-nvme',type:'ZFS',state:'Active',total:'3.84 TiB',used:'1.42 TiB',content:'Disk image, Container'},{name:'backup-store',type:'Proxmox Backup',state:'Active',total:'8 TiB',used:'3.1 TiB',content:'Backup'}],{itemId:'storage',tbar:[{text:'Add',iconCls:'fa fa-plus',menu:[{text:'Directory',handler:showSettings},{text:'ZFS'},{text:'NFS'}]},{text:'Edit',handler:showSettings},{text:'Remove',disabled:true}]});
    const network=grid([{text:'Name',dataIndex:'name',width:120},{text:'Type',dataIndex:'type',width:150},{text:'Active',dataIndex:'state',width:100,renderer:status},{text:'CIDR',dataIndex:'cidr',flex:1},{text:'Gateway',dataIndex:'gateway',width:135},{text:'Comment',dataIndex:'comment',flex:1}],
        [{name:'vmbr0',type:'Linux Bridge',state:'Active',cidr:'192.0.2.10/24',gateway:'192.0.2.1',comment:'Management'},{name:'vmbr1',type:'Linux Bridge',state:'Active',cidr:'198.51.100.10/24',gateway:'',comment:'Guest network'},{name:'eno1',type:'Network Device',state:'Active',cidr:'',gateway:'',comment:'10 GbE uplink'},{name:'eno2',type:'Network Device',state:'Stopped',cidr:'',gateway:'',comment:'Spare uplink'}],{itemId:'network',tbar:[{text:'Create',iconCls:'fa fa-plus',handler:showSettings},{text:'Edit',handler:showSettings},{text:'Remove',disabled:true},'->',{text:'Apply Configuration',disabled:true}]});
    const backup=grid([{text:'Enabled',dataIndex:'enabled',width:85},{text:'Schedule',dataIndex:'schedule',width:130},{text:'Storage',dataIndex:'storage',width:140},{text:'Selection',dataIndex:'selection',flex:1},{text:'Mode',dataIndex:'mode',width:110},{text:'Last run',dataIndex:'state',width:110,renderer:status}],
        [{enabled:'Yes',schedule:'02:00',storage:'backup-store',selection:'100, 101, 102, 104, 105',mode:'Snapshot',state:'OK'},{enabled:'No',schedule:'Sun 03:00',storage:'backup-store',selection:'103',mode:'Snapshot',state:'Warning'}],{itemId:'backup',tbar:[{text:'Add',iconCls:'fa fa-plus',handler:showSettings},{text:'Edit',handler:showSettings},{text:'Run now',disabled:true},{text:'View task log',handler:showLog}]});
    const access=grid([{text:'User name',dataIndex:'name',flex:1},{text:'Realm',dataIndex:'realm',width:160},{text:'Enabled',dataIndex:'enabled',width:110},{text:'Role',dataIndex:'role',width:160},{text:'Expire',dataIndex:'expire',width:130}],
        [{name:'administrator',realm:'pam',enabled:'Yes',role:'Administrator',expire:'Never'},{name:'operations',realm:'pve',enabled:'Yes',role:'PVEAdmin',expire:'Never'},{name:'auditor',realm:'pve',enabled:'Yes',role:'PVEAuditor',expire:'Never'}],{itemId:'access',tbar:[{text:'Add',handler:showSettings},{text:'Edit',handler:showSettings},{text:'Remove',disabled:true},{text:'Login preview',handler:showLogin}]});
    const shell={xtype:'panel',itemId:'shell',title:'Shell',bodyStyle:'background:#101b24;color:#d5e5ee;',bodyPadding:20,html:'<pre style="font:13px/1.8 Consolas,monospace">Linux pve-edge-01 6.8.12-17-pve\n\n<span style="color:#86c7a0">root@pve-edge-01</span>:~# pveversion\npve-manager/8.4.21/2606ac850d46da29\n\n<span style="color:#86c7a0">root@pve-edge-01</span>:~# <span style="background:#b6d7e9;color:#101b24"> </span>\n\nLocal visual fixture. No interactive host connection.</pre>'};
    const tasks=Array.from({length:48},(_,i)=>({start:'2026-10-15 '+String(10-Math.floor(i/10)).padStart(2,'0')+':'+String(59-i%60).padStart(2,'0')+':12',node:i%2?'pve-edge-02':'pve-edge-01',user:'administrator@pam',description:['VM 102 - Backup','VM 101 - Start','Update package database','VM 104 - Snapshot'][i%4],duration:['2m 41s','4s','12s','8s'][i%4],state:i===7?'Warning':'OK'}));
    const taskColumns=[{text:'Start Time',dataIndex:'start',width:170},{text:'Node',dataIndex:'node',width:145},{text:'User name',dataIndex:'user',width:170},{text:'Description',dataIndex:'description',flex:1},{text:'Duration',dataIndex:'duration',width:100},{text:'Status',dataIndex:'state',width:105,renderer:status}];
    const taskGrid=grid(taskColumns,tasks,{title:'Tasks',listeners:{itemdblclick:showLog}});
    const content=Ext.create('Ext.panel.Panel',{region:'center',id:'content',border:false,layout:'border',
        tbar:[{xtype:'tbtext',html:'<span class="x-panel-header-text">Node: pve-edge-01</span>'},'->',{text:'Reboot',iconCls:'fa fa-refresh',disabled:true},{text:'Shutdown',iconCls:'fa fa-power-off',disabled:true},{text:'Shell',iconCls:'fa fa-terminal',handler:()=>select('shell')}],
        items:[{xtype:'panel',region:'west',width:162,border:false,bodyCls:'pve-toolbar-bg',scrollable:true,items:[{xtype:'treelist',reference:'nav',ui:'pve-nav',expanderFirst:false,
            store:Ext.create('Ext.data.TreeStore',{root:{expanded:true,children:[
                {text:'Summary',id:'summary',iconCls:'fa fa-dashboard',leaf:true},{text:'Virtual machines',id:'vms',iconCls:'fa fa-desktop',leaf:true},{text:'Storage',id:'storage',iconCls:'fa fa-database',leaf:true},{text:'Network',id:'network',iconCls:'fa fa-exchange',leaf:true},{text:'Backup',id:'backup',iconCls:'fa fa-history',leaf:true},
                {text:'Permissions',id:'permissions',iconCls:'fa fa-shield',expanded:true,children:[{text:'Users',id:'access',iconCls:'fa fa-user',leaf:true},{text:'Groups',id:'groups',iconCls:'fa fa-users',leaf:true}]},
                {text:'Shell',id:'shell',iconCls:'fa fa-terminal',leaf:true}]} }),listeners:{selectionchange:(t,r)=>{if(r)select(r.id)}}}]},
            {xtype:'panel',itemId:'pages',region:'center',border:false,layout:'card',items:[summary,vms,storage,network,backup,access,shell,grid([{text:'Group name',dataIndex:'name',flex:1},{text:'Comment',dataIndex:'comment',flex:2}],[],{itemId:'groups'})]}]
    });
    function select(id){const pages=content.down('#pages');const c=pages.down('#'+id);if(c)pages.getLayout().setActiveItem(c);location.hash=id;}
    const root=Ext.create('Ext.container.Viewport',{layout:'border',items:[
        {xtype:'container',region:'north',baseCls:'x-plain',layout:{type:'hbox',align:'middle'},margin:'0 0 8 0',items:[
            {xtype:'image',src:'live/usr/share/pve-manager/images/proxmox_logo.png',width:180,height:30,margin:'0 16 0 0'},
            {xtype:'component',id:'versioninfo',html:'Virtual Environment <small style="opacity:.75">8.4.21</small>'},
            {xtype:'component',flex:1},{xtype:'textfield',width:220,emptyText:'Search',margin:'0 18 0 0'},
            {xtype:'button',text:'Create VM',iconCls:'fa fa-desktop',handler:showWizard,margin:'0 8 0 0'},
            {xtype:'button',text:'Preview',margin:'0 8 0 0',menu:[{text:'ESXi Light',handler:()=>switchTheme(false)},{text:'Proxmox default',handler:()=>switchTheme(true)},{text:'Login screen',handler:showLogin},{text:'Task viewer',handler:showLog}]},
            {xtype:'button',id:'userinfo',text:'preview@pam',iconCls:'fa fa-user',menu:[{text:'My Settings',handler:showSettings},{text:'Color Theme',handler:()=>switchTheme(!themeLink.disabled)}]}
        ]},
        {xtype:'treepanel',region:'west',title:'Server View',width:230,minWidth:180,split:true,border:true,rootVisible:false,lines:false,margin:'0 0 0 8',
            store:Ext.create('Ext.data.TreeStore',{root:{expanded:true,children:[{text:'Datacenter',expanded:true,iconCls:'fa fa-building',children:[
                {text:'pve-edge-01',expanded:true,iconCls:'x-tree-icon-custom fa fa-server running',children:vmData.slice(0,3).map(v=>({text:v.id+' ('+v.name+')',leaf:true,iconCls:'x-tree-icon-custom fa fa-desktop running'})).concat([{text:'local (pve-edge-01)',leaf:true,iconCls:'fa fa-database'},{text:'fast-nvme (pve-edge-01)',leaf:true,iconCls:'fa fa-database'}])},
                {text:'pve-edge-02',expanded:true,iconCls:'x-tree-icon-custom fa fa-server running',children:vmData.slice(3).map(v=>({text:v.id+' ('+v.name+')',leaf:true,iconCls:'x-tree-icon-custom fa fa-desktop '+v.state.toLowerCase()}))}
            ]}]}})},
        content,
        {xtype:'tabpanel',region:'south',height:190,minHeight:100,split:true,margin:'8 8 4 8',items:[taskGrid,grid(taskColumns,tasks.slice(0,4),{title:'Cluster log'})]}
    ]});
    function applyTheme(){Ext.ComponentQuery.query('proxmoxRRDChart').forEach(c=>c.checkThemeColors());root.updateLayout();}
    // Re-enabling a stylesheet can complete after the first animation frame.
    // Live Proxmox reloads the page when changing themes; this fixture stays open.
    themeLink.addEventListener('load',applyTheme);
    function switchTheme(disabled){themeLink.disabled=disabled;requestAnimationFrame(applyTheme);}
    content.down('treelist').setSelection('summary');
    if(location.hash)select(location.hash.slice(1));
    window.preview={root,select,showWizard,showSettings,showLog,showLogin,switchTheme};
    window.previewReady=true;
});
