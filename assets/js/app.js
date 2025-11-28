// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.

import "../css/app.scss"
import "@fontsource/inter/variable.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import 'alpinejs'
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import Chart from 'chart.js/auto'

let Hooks = {}

Hooks.VkContainerLog = {
	updated() {
		var logsDiv = document.getElementById("clogsholder")
		logsDiv.scrollTop = logsDiv.scrollHeight
	}
}

Hooks.RenderMarketChart = {
	mounted() {
		this.renderChart()
	},
	updated() {
		this.renderChart()
	},
	renderChart() {
		const data = JSON.parse(this.el.dataset.prices || '[]')
		const canvas = this.el
		
		if (!data || data.length === 0) return
		
		// Destroy existing chart if any
		if (this.chart) {
			this.chart.destroy()
		}

		const labels = data.map(item => {
			const d = new Date(item.date)
			return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
		})

		const prices = data.map(item => parseFloat(item.price).toFixed(4))

		const isDark = document.documentElement.classList.contains('dark')
		const textColor = isDark ? '#9ca3af' : '#6b7280'
		const gridColor = isDark ? 'rgba(75, 85, 99, 0.2)' : 'rgba(0, 0, 0, 0.1)'
		const legendColor = isDark ? '#e5e7eb' : '#374151'

		const ctx = canvas.getContext('2d')
		this.chart = new Chart(ctx, {
			type: 'line',
			data: {
				labels: labels,
				datasets: [{
					label: 'ZCL Price (USD)',
					data: prices,
					borderColor: '#16a34a',
					backgroundColor: 'rgba(22, 163, 74, 0.1)',
					borderWidth: 2,
					fill: true,
					tension: 0.4,
					pointRadius: 3,
					pointBackgroundColor: '#16a34a',
					pointBorderColor: '#ffffff',
					pointBorderWidth: 1,
					pointHoverRadius: 5
				}]
			},
			options: {
				responsive: true,
				maintainAspectRatio: true,
				plugins: {
					legend: {
						display: true,
						labels: {
							color: legendColor,
							font: { size: 12 }
						}
					}
				},
				scales: {
					y: {
						beginAtZero: false,
						ticks: {
							color: textColor,
							callback: function(value) {
								return '$' + parseFloat(value).toFixed(4)
							}
						},
						grid: {
							color: gridColor
						}
					},
					x: {
						ticks: {
							color: textColor
						},
						grid: {
							display: false
						}
					}
				}
			}
		})
	}
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })
liveSocket.connect()
window.liveSocket = liveSocket
liveSocket.enableDebug()

var themeToggleDarkIcon = document.getElementById('theme-toggle-dark-icon');
var themeToggleLightIcon = document.getElementById('theme-toggle-light-icon');

// Change the icons inside the button based on previous settings
if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
	themeToggleLightIcon.classList.remove('hidden');
} else {
	themeToggleDarkIcon.classList.remove('hidden');
}

var themeToggleBtn = document.getElementById('theme-toggle');

themeToggleBtn.addEventListener('click', function () {

	// toggle icons inside button
	themeToggleDarkIcon.classList.toggle('hidden');
	themeToggleLightIcon.classList.toggle('hidden');

	// if set via local storage previously
	if (localStorage.getItem('color-theme')) {
		if (localStorage.getItem('color-theme') === 'light') {
			document.documentElement.classList.add('dark');
			localStorage.setItem('color-theme', 'dark');
		} else {
			document.documentElement.classList.remove('dark');
			localStorage.setItem('color-theme', 'light');
		}

		// if NOT set via local storage previously
	} else {
		if (document.documentElement.classList.contains('dark')) {
			document.documentElement.classList.remove('dark');
			localStorage.setItem('color-theme', 'light');
		} else {
			document.documentElement.classList.add('dark');
			localStorage.setItem('color-theme', 'dark');
		}
	}

});