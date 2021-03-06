<!DOCTYPE html>
<html lang="zh-CN">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="description" content="我编程三日，两耳不闻人声，只有硬盘在歌唱。">
	<meta name="keywords" content="黄梦龙,游戏开发,游戏程序,游戏服务器,Go语言,Golang,数据库,分布式系统,分布式数据库">
	<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">

	<!-- Set render engine for 360 browser -->
	<meta name="renderer" content="webkit">

	<!-- No Baidu Siteapp-->
	<meta http-equiv="Cache-Control" content="no-siteapp"/>

	<link rel="icon" type="image/png" href="assets/img/favicon.png">

	<link rel="stylesheet" href="http://apps.bdimg.com/libs/fontawesome/4.2.0/css/font-awesome.min.css">
	<link rel="stylesheet" href="/assets/css/screen.css">

	<title>硬盘在歌唱</title>

	<script>
		var _hmt = _hmt || [];
		(function() {
			var hm = document.createElement("script");
			hm.src = "//hm.baidu.com/hm.js?e0811847abcff7c3962075668a8d15ca";
			var s = document.getElementsByTagName("script")[0]; 
			s.parentNode.insertBefore(hm, s);
		})();
	</script>
</head>

<body>
<div class="container">
	<header>
		<h1><i class="fa fa-music"></i> 硬盘在歌唱 <i class="fa fa-music"></i></h1>
		<p>我编程三日，两耳不闻人声，只有硬盘在歌唱。</p>
	</header>

	{{range .}}
	<div>
		<h2><i class="fa fa-pencil"></i> {{.Title}}</h2>
			{{if .Description}} <p class="desc">{{.Description}}</p> {{end}}
			{{range .Posts}}
				<p>
					<a href="/{{.Name}}">{{.Title}}</a>
					{{if .Description}} <p class="desc">{{.Description}}</p> {{end}}
				</p>
			{{end}}
	</div>
	{{end}}

	<section class="about">
	<div>
		<h2><i class="fa fa-user"></i> 关于作者</h2>
		<p>黄梦龙，88年生程序员，有多年游戏服务器开发背景，现于北京开发开源数据库产品。我是曾经的重度网游沉迷者、曾经的科幻爱好者、曾经的跑步爱好者。</p>
		<p>我热爱编程，高中时由于不想听课自学了BASIC，在文曲星上编写小游戏在同学间传播，后来很幸运报考大学时选择了理想的专业，毕业后又开始了理想中的工作，build something的快乐一直伴随着我，希望能在技术的道路上一直走下去。</p>
		<p>你可以通过以下各种方式找到我，欢迎Follow：</p>
		<p>
			<i class="fa fa-envelope-o fa-2x"></i><a href="mailto:i@disksing.com">电子邮件</a>
			<i class="fa fa-github-alt fa-2x"></i><a href="https://github.com/disksing">GitHub</a>
			<i class="fa fa-weibo fa-2x"></i><a href="http://weibo.com/539523448">新浪微博</a>
			<i class="fa fa-twitter fa-2x"></i><a href="https://twitter.com/disksing">Twitter</a>
		</p>
	</div>

	<div>
		<h2><i class="fa fa-flag"></i> 关于本站</h2>
		<p>本站目前的定位是个人博客，主要的主题是游戏服务器编程、Go语言和分布式数据库，使用Go语言开发，代码和文章托管在GitHub，网站托管在阿里云ECS。</p>
		<p><i class="fa fa-quote-left"></i>我编程三日，两耳不闻人声，只有硬盘在歌唱。<i class="fa fa-quote-right"></i> ——选自《编程之禅 水卷》</p>
		<p>
			<i class="fa fa-github fa-2x"></i><a href="https://github.com/disksing/blog">项目主页</a>
			<i class="fa fa-bug fa-2x"></i><a href="https://github.com/disksing/blog/issues">遇到问题？</a>
		</p>
	</div>
	</section>

	<footer>
		<p>本站文章采用<a rel="license" href="http://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>进行许可，文中涉及代码采用<a rel="license" href="http://creativecommons.org/publicdomain/zero/1.0/">CC0 1.0 Universal</a>进行许可</p>
		<p>订阅本站文章：<a href="http://disksing.com/feed" target="_blank"><i class="fa fa-rss-square"></i>ATOM</a>  <a href="http://disksing.com/rss" target="_blank"><i class="fa fa-rss-square"></i>RSS</a></p>
		<p><a href="http://disksing.com/"><i class="fa fa-music"></i> 硬盘在歌唱 <i class="fa fa-music"></i></a> <i class="fa fa-copyright"></i> 2015</p>
	</footer>
</div>
</body>
</html>