import React from 'react'
import { motion } from 'framer-motion'
import { UserPlus, Settings, Rocket } from 'lucide-react'

const HowItWorks = ({ onOpenModal }) => {
  const steps = [
    {
      number: '01',
      icon: UserPlus,
      title: 'Настройка бизнеса',
      description: 'Мы создаем ваш бизнес в системе и настраиваем админ-панель. Вы получаете доступ для управления товарами и заказами.',
    },
    {
      number: '02',
      icon: Settings,
      title: 'Заполнение каталога',
      description: 'Вы добавляете товары через админ-панель: кофе, десерты, напитки с фото и ценами. Настраиваем оплату и доставку.',
    },
    {
      number: '03',
      icon: Rocket,
      title: 'Запуск магазина',
      description: 'Подключаем Telegram бота с Mini App. Ваши клиенты смогут заказывать прямо в Telegram, а вы управляете заказами в админ-панели.',
    },
  ]

  return (
    <section id="how-it-works" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Как это{' '}
            <span className="text-gradient">работает</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto mb-8">
            Запустите свою кофейню в Telegram всего за 3 простых шага
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8 mb-12">
          {steps.map((step, index) => (
            <motion.div
              key={step.number}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="relative bg-gradient-to-br from-coffee-50 to-white rounded-2xl p-8 border border-coffee-100 hover:shadow-xl transition-all flex flex-col h-full"
            >
              <div className="absolute -top-4 -left-4 w-12 h-12 bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 rounded-full flex items-center justify-center text-white font-bold text-lg">
                {step.number}
              </div>
              <div className="w-16 h-16 bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 rounded-xl flex items-center justify-center mb-6 mt-4">
                <step.icon className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                {step.title}
              </h3>
              <p className="text-gray-600 leading-relaxed flex-grow">
                {step.description}
              </p>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="text-center"
        >
          <button
            onClick={onOpenModal}
            className="inline-block bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 text-white px-8 py-4 rounded-full font-semibold text-lg shadow-lg hover:shadow-xl transition-all hover:scale-105"
          >
            Начать бесплатно
          </button>
        </motion.div>
      </div>
    </section>
  )
}

export default HowItWorks

