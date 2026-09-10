"use strict";(self.webpackChunkfrontend=self.webpackChunkfrontend||[]).push([["6957"],{24270(e,t,a){a.d(t,{FI:()=>p,GA:()=>v,MX:()=>s,VP:()=>m,XZ:()=>c,lC:()=>u,oc:()=>h,p0:()=>b,pS:()=>o,u3:()=>i,vq:()=>d});var l=a(46831),r=a(85020);let{t:n}=l.Ru.global;function i(e){return r.K.get("/batch_mail/task/list",{params:e})}function o(e){return r.K.get("/batch_mail/task/stat_chart",{params:e})}function s(e){return r.K.get("/batch_mail/task/find",{params:e})}function c(e){return r.K.post("/batch_mail/task/create",e,{fetchOptions:{loading:n("market.task.loading.creating"),successMessage:!0}})}function u(e){return r.K.post("/batch_mail/task/update",e,{fetchOptions:{loading:n("market.task.loading.updating"),successMessage:!0}})}function d(e){return r.K.post("/batch_mail/task/delete",e,{fetchOptions:{loading:n("market.task.loading.deleting"),successMessage:!0}})}function v(e){return r.K.post("/batch_mail/task/pause",e,{fetchOptions:{loading:n("market.task.loading.pausing"),successMessage:!0}})}function m(e){return r.K.post("/batch_mail/task/resume",e,{fetchOptions:{loading:n("market.task.loading.resuming"),successMessage:!0}})}function p(e){return r.K.post("/batch_mail/task/send_test",e,{fetchOptions:{loading:n("market.task.loading.sendingTest"),successMessage:!0}})}function b(e){return r.K.get("/batch_mail/tracking/mail_provider",{params:e})}function h(e){return r.K.get("/batch_mail/tracking/logs",{params:e})}},78045(e,t,a){a.r(t),a.d(t,{default:()=>W});var l=a(23141),r=a(51625),n=a(5887),i=a(99076),o=a(90290),s=a(12268),c=a(6463),u=a(16172),d=a(12532);let v={class:"bt-time-range"},m=(0,o.pM)({__name:"index",props:(0,o.zz)({defaultType:{type:String,default:"today"}},{value:{},valueModifiers:{}}),emits:(0,o.zz)(["change"],["update:value"]),setup(e,t){let{emit:a}=t,l=(0,o.fn)(e,"value"),m=(0,o.KR)(e.defaultType),p=e=>{switch(e){case"today":l.value=(0,d.JZ)();break;case"yesterday":l.value=(0,d.JZ)((0,u.f)(new Date,-1));break;case"last7days":let t,r;t=new Date,r=(0,s.D)(t),l.value=[(0,c.o)((0,u.f)(t,-6)).getTime(),r.getTime()]}a("change")},b=e=>{let t=new Date,a=(0,u.f)(t,-30);return(0,c.o)(a).getTime()>e||(0,s.D)(t).getTime()<e},h=e=>{m.value="custom",l.value=[(0,c.o)(e[0]).getTime(),(0,s.D)(e[1]).getTime()],a("change")};return p(e.defaultType),(e,t)=>{let a=i.A,s=n.A,c=r.A;return(0,o.uX)(),(0,o.CE)("div",v,[(0,o.bF)(s,{value:(0,o.R1)(m),"onUpdate:value":[t[0]||(t[0]=e=>(0,o.i9)(m)?m.value=e:null),p]},{default:(0,o.k6)(()=>[(0,o.bF)(a,{value:"today"},{default:(0,o.k6)(()=>[(0,o.eW)((0,o.v_)(e.$t("common.time.today")),1)]),_:1}),(0,o.bF)(a,{value:"yesterday"},{default:(0,o.k6)(()=>[(0,o.eW)((0,o.v_)(e.$t("common.time.yesterday")),1)]),_:1}),(0,o.bF)(a,{value:"last7days"},{default:(0,o.k6)(()=>[(0,o.eW)((0,o.v_)(e.$t("common.time.last7days")),1)]),_:1})]),_:1},8,["value"]),(0,o.bF)(c,{value:l.value,type:"daterange","is-date-disabled":b,"onUpdate:value":h},null,8,["value"])])}}});var p=a(64901);let b=(0,p.default)(m,[["__scopeId","data-v-a8143a3f"]]);var h=a(29252),f=a(62606),k=a(4374),g=a(24270),_=a(40047),y=a(19158),w=a(85956),x=a(27428),R=a(75220),K=a(3401);let F={class:"p-20px"},A={class:"flex justify-between items-center mb-20px"},E={class:"font-bold text-basic"},M={class:"metrics-cards"},C={class:"detail-row"},z={class:"rate-charts-card"},B=(0,o.pM)({__name:"analytics",setup(e){let t=(0,R.lq)(),{t:a}=(0,K.s9)(),r=(0,o.EW)(()=>(0,d.WZ)(t.params.id||"0")),n=(0,o.KR)((0,d.JZ)()),i=(0,o.KR)([]),s=(0,o.Kh)({delivery_rate:{label:a("overview.delivered"),value:0,unit:"%"},open_rate:{label:a("overview.opened"),value:0,unit:"%"},click_rate:{label:a("overview.clicked"),value:0,unit:"%"},bounce_rate:{label:a("overview.bounced"),value:0,unit:"%"}}),c=(0,o.KR)({column_type:"hourly",dashboard:{delivered:0,delivery_rate:0,failed:0,failure_rate:0,sends:0},data:[]}),u=(0,o.KR)({column_type:"hourly",data:[]}),v=(0,o.KR)({column_type:"hourly",data:[]}),m=(0,o.KR)({column_type:"hourly",data:[]});async function p(){let e=await (0,g.pS)({task_id:r.value,start_time:Math.floor(n.value[0]/1e3),end_time:Math.floor(n.value[1]/1e3)});(0,d.Gv)(e)&&(Object.entries(e.dashboard).forEach(e=>{let[t,a]=e;t in s&&(s[t].value=a)}),i.value=(0,d.cy)(e.mail_providers)?e.mail_providers:[],c.value=e.send_mail_chart,u.value=e.bounce_rate_chart,v.value=e.click_rate_chart,m.value=e.open_rate_chart)}let B=(0,o.KR)("");return(async()=>{let e=await (0,g.MX)({id:r.value});(0,d.Gv)(e)&&(B.value=e.subject)})(),(e,t)=>{let a=(0,o.g2)("router-link"),r=k.A,d=f.Ay,g=h.Ay,R=l.Ay;return(0,o.uX)(),(0,o.CE)("div",F,[(0,o.Lk)("div",A,[(0,o.bF)(g,null,{default:(0,o.k6)(()=>[(0,o.bF)(r,null,{default:(0,o.k6)(()=>[(0,o.bF)(a,{to:"/market/task"},{default:(0,o.k6)(()=>[(0,o.eW)((0,o.v_)(e.$t("market.task.title")),1)]),_:1})]),_:1}),(0,o.bF)(r,null,{default:(0,o.k6)(()=>[(0,o.eW)((0,o.v_)(e.$t("market.task.actions.analytics")),1)]),_:1}),(0,o.bF)(r,null,{default:(0,o.k6)(()=>[(0,o.bF)(d,{style:{"max-width":"300px"}},{default:(0,o.k6)(()=>[(0,o.Lk)("span",E,(0,o.v_)((0,o.R1)(B)||"--"),1)]),_:1})]),_:1})]),_:1}),(0,o.bF)(b,{value:(0,o.R1)(n),"onUpdate:value":t[0]||(t[0]=e=>(0,o.i9)(n)?n.value=e:null),"default-type":"last7days",onChange:p},null,8,["value"])]),(0,o.Lk)("div",M,[((0,o.uX)(!0),(0,o.CE)(o.FK,null,(0,o.pI)((0,o.R1)(s),(e,t)=>((0,o.uX)(),(0,o.Wv)(_.A,{key:t,title:e.label,value:e.value,unit:e.unit},null,8,["title","value","unit"]))),128))]),(0,o.Lk)("div",C,[(0,o.bF)(R,{class:"provider-table-card",title:e.$t("overview.mailProviders")},{default:(0,o.k6)(()=>[(0,o.bF)(y.A,{value:(0,o.R1)(i),"onUpdate:value":t[1]||(t[1]=e=>(0,o.i9)(i)?i.value=e:null)},null,8,["value"])]),_:1},8,["title"]),(0,o.bF)(R,{class:"send-today-card",title:e.$t("overview.sendStats")},{default:(0,o.k6)(()=>[(0,o.bF)(w.A,{data:(0,o.R1)(c)},null,8,["data"])]),_:1},8,["title"])]),(0,o.Lk)("div",z,[(0,o.bF)(x.A,{bounce:(0,o.R1)(u),click:(0,o.R1)(v),open:(0,o.R1)(m)},null,8,["bounce","click","open"])])])}}}),W=(0,p.default)(B,[["__scopeId","data-v-34cf85db"]])},29252(e,t,a){a.d(t,{s7:()=>d,Ay:()=>m});var l=a(90290),r=a(49359),n=a(50922),i=a(4019),o=a(29794),s=a(23766),c=a(75454);let u=(0,c.cB)("breadcrumb",`
 white-space: nowrap;
 cursor: default;
 line-height: var(--n-item-line-height);
`,[(0,c.c)("ul",`
 list-style: none;
 padding: 0;
 margin: 0;
 `),(0,c.c)("a",`
 color: inherit;
 text-decoration: inherit;
 `),(0,c.cB)("breadcrumb-item",`
 font-size: var(--n-font-size);
 transition: color .3s var(--n-bezier);
 display: inline-flex;
 align-items: center;
 `,[(0,c.cB)("icon",`
 font-size: 18px;
 vertical-align: -.2em;
 transition: color .3s var(--n-bezier);
 color: var(--n-item-text-color);
 `),(0,c.c)("&:not(:last-child)",[(0,c.cM)("clickable",[(0,c.cE)("link",`
 cursor: pointer;
 `,[(0,c.c)("&:hover",`
 background-color: var(--n-item-color-hover);
 `),(0,c.c)("&:active",`
 background-color: var(--n-item-color-pressed); 
 `)])])]),(0,c.cE)("link",`
 padding: 4px;
 border-radius: var(--n-item-border-radius);
 transition:
 background-color .3s var(--n-bezier),
 color .3s var(--n-bezier);
 color: var(--n-item-text-color);
 position: relative;
 `,[(0,c.c)("&:hover",`
 color: var(--n-item-text-color-hover);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-hover);
 `)]),(0,c.c)("&:active",`
 color: var(--n-item-text-color-pressed);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-pressed);
 `)])]),(0,c.cE)("separator",`
 margin: 0 8px;
 color: var(--n-separator-color);
 transition: color .3s var(--n-bezier);
 user-select: none;
 -webkit-user-select: none;
 `),(0,c.c)("&:last-child",[(0,c.cE)("link",`
 font-weight: var(--n-font-weight-active);
 cursor: unset;
 color: var(--n-item-text-color-active);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-active);
 `)]),(0,c.cE)("separator",`
 display: none;
 `)])])]),d=(0,o.D)("n-breadcrumb"),v=Object.assign(Object.assign({},r.A.props),{separator:{type:String,default:"/"}}),m=(0,l.pM)({name:"Breadcrumb",props:v,setup(e){let{mergedClsPrefixRef:t,inlineThemeDisabled:a}=(0,n.Ay)(e),o=(0,r.A)("Breadcrumb","-breadcrumb",u,s.A,e,t);(0,l.Gt)(d,{separatorRef:(0,l.lW)(e,"separator"),mergedClsPrefixRef:t});let c=(0,l.EW)(()=>{let{common:{cubicBezierEaseInOut:e},self:{separatorColor:t,itemTextColor:a,itemTextColorHover:l,itemTextColorPressed:r,itemTextColorActive:n,fontSize:i,fontWeightActive:s,itemBorderRadius:c,itemColorHover:u,itemColorPressed:d,itemLineHeight:v}}=o.value;return{"--n-font-size":i,"--n-bezier":e,"--n-item-text-color":a,"--n-item-text-color-hover":l,"--n-item-text-color-pressed":r,"--n-item-text-color-active":n,"--n-separator-color":t,"--n-item-color-hover":u,"--n-item-color-pressed":d,"--n-item-border-radius":c,"--n-font-weight-active":s,"--n-item-line-height":v}}),v=a?(0,i.R)("breadcrumb",void 0,c,e):void 0;return{mergedClsPrefix:t,cssVars:a?void 0:c,themeClass:null==v?void 0:v.themeClass,onRender:null==v?void 0:v.onRender}},render(){var e;return null==(e=this.onRender)||e.call(this),(0,l.h)("nav",{class:[`${this.mergedClsPrefix}-breadcrumb`,this.themeClass],style:this.cssVars,"aria-label":"Breadcrumb"},(0,l.h)("ul",null,this.$slots))}})},4374(e,t,a){a.d(t,{A:()=>o});var l=a(90290),r=a(49521),n=a(91900),i=a(29252);let o=(0,l.pM)({name:"BreadcrumbItem",props:{separator:String,href:String,clickable:{type:Boolean,default:!0},showSeparator:{type:Boolean,default:!0},onClick:Function},slots:Object,setup(e,{slots:t}){let a=(0,l.WQ)(i.s7,null);if(!a)return()=>null;let{separatorRef:o,mergedClsPrefixRef:s}=a,c=function(e=n.B?window:null){let t=()=>{let{hash:t,host:a,hostname:l,href:r,origin:n,pathname:i,port:o,protocol:s,search:c}=(null==e?void 0:e.location)||{};return{hash:t,host:a,hostname:l,href:r,origin:n,pathname:i,port:o,protocol:s,search:c}},a=(0,l.KR)(t()),r=()=>{a.value=t()};return(0,l.sV)(()=>{e&&(e.addEventListener("popstate",r),e.addEventListener("hashchange",r))}),(0,l.hi)(()=>{e&&(e.removeEventListener("popstate",r),e.removeEventListener("hashchange",r))}),a}(),u=(0,l.EW)(()=>e.href?"a":"span"),d=(0,l.EW)(()=>c.value.href===e.href?"location":null);return()=>{let{value:a}=s;return(0,l.h)("li",{class:[`${a}-breadcrumb-item`,e.clickable&&`${a}-breadcrumb-item--clickable`]},(0,l.h)(u.value,{class:`${a}-breadcrumb-item__link`,"aria-current":d.value,href:e.href,onClick:e.onClick},t),e.showSeparator&&(0,l.h)("span",{class:`${a}-breadcrumb-item__separator`,"aria-hidden":"true"},(0,r.Nj)(t.separator,()=>{var t;return[null!=(t=e.separator)?t:o.value]})))}}})}}]);