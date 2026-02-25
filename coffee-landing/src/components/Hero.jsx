import React from 'react'
import { motion } from 'framer-motion'
import { ArrowRight, Coffee, ShoppingBag, Clock, Target, CreditCard, Truck } from 'lucide-react'

const Hero = ({ onOpenModal }) => {
  return (
    <section className="pt-28 pb-16 md:pt-40 md:pb-24 bg-gradient-to-br from-coffee-50 via-white to-coffee-50 relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 left-0 w-96 h-96 bg-coffee-600 rounded-full filter blur-3xl"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-coffee-800 rounded-full filter blur-3xl"></div>
      </div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          {/* Left Column - Text */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center gap-2 bg-coffee-100 text-coffee-700 px-4 py-2 rounded-full text-sm font-semibold mb-6">
              <Coffee className="w-4 h-4" />
              Кофейный бизнес в Telegram
            </div>
            <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              Ваша кофейня в{' '}
              <span className="text-gradient">Telegram</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
              Готовое решение Telegram Mini App для вашей кофейни.
              Каталог напитков, онлайн-оплата, доставка и админ-панель — всё готово к работе.
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <motion.button
                onClick={onOpenModal}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="group bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white px-8 py-4 rounded-full font-semibold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center"
              >
                Начать бесплатно
                <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </motion.button>
              <motion.a
                href="#how-it-works"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="border-2 border-coffee-600 text-coffee-700 px-8 py-4 rounded-full font-semibold text-lg hover:bg-coffee-50 transition-all"
              >
                Узнать больше
              </motion.a>
            </div>
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
                    <div className="bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 p-6 text-white">
                      <div className="flex items-center justify-between mb-4">
                        <h3 className="text-xl font-bold">Моя кофейня</h3>
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
                          <div className="w-20 h-20 bg-coffee-200 rounded-lg"></div>
                          <div className="flex-1">
                            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                            <div className="h-3 bg-gray-200 rounded w-1/2 mb-2"></div>
                            <div className="h-4 bg-coffee-200 rounded w-1/4"></div>
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
                <CreditCard className="w-6 h-6 text-coffee-700 mb-2" />
                <div className="text-sm font-semibold text-gray-900">Оплата</div>
              </motion.div>

              <motion.div
                animate={{ y: [0, 20, 0] }}
                transition={{ duration: 3, repeat: Infinity, delay: 1 }}
                className="absolute -bottom-10 -left-10 bg-white p-4 rounded-2xl shadow-xl"
              >
                <Truck className="w-6 h-6 text-coffee-700 mb-2" />
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

