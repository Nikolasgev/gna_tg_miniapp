import React from 'react'
import { motion } from 'framer-motion'
import { ArrowRight, Play, CheckCircle2, Rocket, Target, CreditCard, Truck } from 'lucide-react'

const Hero = ({ onOpenModal }) => {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-50 via-white to-gray-50 pt-12">
      {/* Animated Background */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-slate-300 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-float"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-gray-300 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-float" style={{ animationDelay: '2s' }}></div>
      </div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left Column - Text */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center lg:text-left"
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="inline-block mb-4"
            >
              <span className="bg-slate-100 text-slate-700 px-4 py-1.5 rounded-full text-sm font-semibold flex items-center gap-2">
                <Rocket className="w-4 h-4" />
                Запуск за 5 минут
              </span>
            </motion.div>

            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              Создайте{' '}
              <span className="text-gradient">интернет-магазин</span>
              <br />
              в Telegram за минуты
            </h1>

            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
              Готовое решение Telegram Mini App для вашего бизнеса.
              Каталог товаров, онлайн-оплата, доставка и админ-панель — всё готово к работе.
            </p>

            {/* Features List */}
            <div className="flex flex-col sm:flex-row sm:items-center gap-4 mb-8">
              <div className="flex items-center text-gray-700">
                <CheckCircle2 className="w-5 h-5 text-slate-600 mr-2" />
                <span className="font-medium">Без программирования</span>
              </div>
              <div className="flex items-center text-gray-700">
                <CheckCircle2 className="w-5 h-5 text-slate-600 mr-2" />
                <span className="font-medium">Готово к работе</span>
              </div>
              <div className="flex items-center text-gray-700">
                <CheckCircle2 className="w-5 h-5 text-slate-600 mr-2" />
                <span className="font-medium">Бесплатный старт</span>
              </div>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <motion.button
                onClick={onOpenModal}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="group bg-gradient-to-r from-slate-700 to-slate-900 text-white px-8 py-4 rounded-full font-semibold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center"
              >
                Начать бесплатно
                <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </motion.button>
              <motion.a
                href="#how-it-works"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="bg-white text-gray-700 px-8 py-4 rounded-full font-semibold text-lg border-2 border-gray-200 hover:border-slate-300 transition-all flex items-center justify-center"
              >
                <Play className="mr-2 w-5 h-5" />
                Смотреть демо
              </motion.a>
            </div>

            {/* Trust Indicators */}
          </motion.div>

          {/* Right Column - Visual */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="relative"
          >
            <div className="relative">
              {/* Phone Mockup */}
              <div className="relative mx-auto max-w-sm">
                <div className="bg-gray-900 rounded-[3rem] p-4 shadow-2xl">
                  <div className="bg-white rounded-[2.5rem] overflow-hidden">
                    <div className="bg-gradient-to-br from-slate-700 to-slate-900 p-6 text-white">
                      <div className="flex items-center justify-between mb-4">
                        <h3 className="text-xl font-bold">Мой магазин</h3>
                        <div className="w-8 h-8 bg-white/20 rounded-full"></div>
                      </div>
                      <div className="space-y-3">
                        <div className="bg-white/20 rounded-lg p-3">
                          <div className="h-4 bg-white/30 rounded w-3/4 mb-2"></div>
                          <div className="h-3 bg-white/20 rounded w-1/2"></div>
                        </div>
                        <div className="bg-white/20 rounded-lg p-3">
                          <div className="h-4 bg-white/30 rounded w-2/3 mb-2"></div>
                          <div className="h-3 bg-white/20 rounded w-1/2"></div>
                        </div>
                      </div>
                    </div>
                    <div className="p-4 space-y-3">
                      {[1, 2, 3].map((i) => (
                        <div key={i} className="flex gap-3">
                          <div className="w-20 h-20 bg-gray-200 rounded-lg"></div>
                          <div className="flex-1">
                            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                            <div className="h-3 bg-gray-200 rounded w-1/2 mb-2"></div>
                            <div className="h-4 bg-slate-200 rounded w-1/4"></div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* Floating Elements */}
              <motion.div
                animate={{ y: [0, -20, 0] }}
                transition={{ duration: 3, repeat: Infinity }}
                className="absolute -top-10 -right-10 bg-white p-4 rounded-2xl shadow-xl"
              >
                <CreditCard className="w-6 h-6 text-slate-700 mb-2" />
                <div className="text-sm font-semibold text-gray-900">Оплата</div>
              </motion.div>

              <motion.div
                animate={{ y: [0, 20, 0] }}
                transition={{ duration: 3, repeat: Infinity, delay: 1 }}
                className="absolute -bottom-10 -left-10 bg-white p-4 rounded-2xl shadow-xl"
              >
                <Truck className="w-6 h-6 text-slate-700 mb-2" />
                <div className="text-sm font-semibold text-gray-900">Доставка</div>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Hero

